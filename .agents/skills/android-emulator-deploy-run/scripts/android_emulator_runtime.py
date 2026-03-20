#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

POLL_INTERVAL_SECONDS = 0.5
EMULATOR_LAUNCH_ATTEMPTS = 3
EMULATOR_LAUNCH_RETRY_DELAY_SECONDS = 5.0
DEFAULT_HOST_AVD_HOME = Path.home() / ".android" / "avd"
PATH_POLICY_REPO_LOCAL = "repo-local"
PATH_POLICY_HOST_DEFAULT = "host-default"
PACKAGE_NAME_RE = re.compile(r"package: name='([^']+)'")
LAUNCHABLE_ACTIVITY_RE = re.compile(r"launchable-activity: name='([^']+)'")
ACTIVITY_START_ERROR_PREFIXES = (
    "Error:",
    "Error type",
    "Exception occurred while executing",
    "java.lang.",
    "Security exception:",
)


@dataclass(frozen=True)
class Device:
    serial: str
    state: str
    details: dict[str, str]

    @property
    def is_emulator(self) -> bool:
        return self.serial.startswith("emulator-")


@dataclass(frozen=True)
class ApkMetadata:
    package_name: str | None
    launchable_activity: str | None


@dataclass(frozen=True)
class RuntimeLayout:
    env: dict[str, str]
    source: str
    path_policy: str
    emulator_home: Path | None
    avd_home: Path | None
    datadir_root: Path | None
    log_dir: Path


def resolve_workspace_root() -> Path:
    script_path = Path(__file__).resolve()
    for parent in script_path.parents:
        if (parent / ".agents").exists() and (parent / "AGENTS.md").exists():
            return parent
    return Path.cwd().resolve()


WORKSPACE_ROOT = resolve_workspace_root()
WORKSPACE_EMULATOR_HOME = WORKSPACE_ROOT / ".cache" / "android-avd-home"
WORKSPACE_AVD_HOME = WORKSPACE_EMULATOR_HOME / "avd"
WORKSPACE_DATADIR_ROOT = WORKSPACE_ROOT / ".cache" / "android-avd-data"
WORKSPACE_LOG_DIR = WORKSPACE_ROOT / ".cache" / "android-emulator-deploy-run"


def command_output(
    command: Sequence[str],
    *,
    text: bool = True,
    check: bool = True,
    timeout: float | None = None,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str] | subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(
            list(command),
            capture_output=True,
            text=text,
            check=check,
            timeout=timeout,
            env=env,
        )
    except subprocess.CalledProcessError as exc:
        stdout = exc.stdout.decode("utf-8", errors="replace") if isinstance(exc.stdout, bytes) else exc.stdout
        stderr = exc.stderr.decode("utf-8", errors="replace") if isinstance(exc.stderr, bytes) else exc.stderr
        message = [f"Command failed: {' '.join(command)}"]
        if stdout:
            message.append(f"stdout:\n{stdout.strip()}")
        if stderr:
            message.append(f"stderr:\n{stderr.strip()}")
        raise SystemExit("\n".join(message)) from exc
    except FileNotFoundError as exc:
        raise SystemExit(f"Command not found: {command[0]}") from exc


def normalize_path(raw_path: str) -> Path:
    return Path(raw_path).expanduser().resolve()


def resolve_sdk_root() -> Path | None:
    sdk_root = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    return normalize_path(sdk_root) if sdk_root else None


def existing_candidate(candidates: Sequence[Path]) -> str | None:
    seen: set[Path] = set()
    for candidate in candidates:
        resolved = candidate.expanduser()
        if resolved in seen:
            continue
        seen.add(resolved)
        if resolved.exists():
            return str(resolved)
    return None


def resolve_adb() -> str:
    candidates: list[Path] = []
    sdk_root = resolve_sdk_root()
    if sdk_root is not None:
        candidates.append(sdk_root / "platform-tools" / "adb")
    emulator_path = shutil.which("emulator")
    if emulator_path:
        candidates.append(Path(emulator_path).resolve().parents[1] / "platform-tools" / "adb")
    adb_path = shutil.which("adb")
    if adb_path:
        candidates.append(Path(adb_path))
    resolved = existing_candidate(candidates)
    if not resolved:
        raise SystemExit("Unable to find adb. Set ANDROID_SDK_ROOT/ANDROID_HOME or put adb on PATH.")
    return resolved


def resolve_emulator() -> str:
    candidates: list[Path] = []
    sdk_root = resolve_sdk_root()
    if sdk_root is not None:
        candidates.append(sdk_root / "emulator" / "emulator")
    adb_path = existing_candidate([Path(resolve_adb())])
    if adb_path:
        candidates.append(Path(adb_path).resolve().parents[1] / "emulator" / "emulator")
    emulator_path = shutil.which("emulator")
    if emulator_path:
        candidates.append(Path(emulator_path))
    resolved = existing_candidate(candidates)
    if not resolved:
        raise SystemExit("Unable to find the Android emulator binary. Set ANDROID_SDK_ROOT/ANDROID_HOME or put emulator on PATH.")
    return resolved


def resolve_aapt() -> str | None:
    candidates: list[Path] = []
    sdk_root = resolve_sdk_root()
    if sdk_root is not None:
        build_tools_dir = sdk_root / "build-tools"
        if build_tools_dir.exists():
            for child in sorted(build_tools_dir.iterdir(), reverse=True):
                candidates.append(child / "aapt")
    aapt_path = shutil.which("aapt")
    if aapt_path:
        candidates.append(Path(aapt_path))
    return existing_candidate(candidates)


def resolve_apkanalyzer() -> str | None:
    candidates: list[Path] = []
    sdk_root = resolve_sdk_root()
    if sdk_root is not None:
        candidates.extend(
            [
                sdk_root / "cmdline-tools" / "latest" / "bin" / "apkanalyzer",
                sdk_root / "tools" / "bin" / "apkanalyzer",
            ]
        )
    apkanalyzer_path = shutil.which("apkanalyzer")
    if apkanalyzer_path:
        candidates.append(Path(apkanalyzer_path))
    return existing_candidate(candidates)


def adb_command(serial: str | None, *parts: str) -> list[str]:
    command = [resolve_adb()]
    if serial:
        command.extend(["-s", serial])
    command.extend(parts)
    return command


def parse_devices(raw_output: str) -> list[Device]:
    devices: list[Device] = []
    for line in raw_output.splitlines():
        line = line.strip()
        if not line or line.startswith("* daemon") or line.startswith("List of devices attached"):
            continue
        columns = line.split()
        serial = columns[0]
        state = columns[1] if len(columns) > 1 else "unknown"
        details: dict[str, str] = {}
        for column in columns[2:]:
            if ":" in column:
                key, value = column.split(":", 1)
                details[key] = value
        devices.append(Device(serial=serial, state=state, details=details))
    return devices


def list_devices() -> list[Device]:
    result = command_output([resolve_adb(), "devices", "-l"])
    assert isinstance(result.stdout, str)
    return parse_devices(result.stdout)


def list_avds(env: dict[str, str] | None = None) -> list[str]:
    result = command_output([resolve_emulator(), "-list-avds"], env=env)
    assert isinstance(result.stdout, str)
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def avd_home_has_definitions(avd_home: Path) -> bool:
    if not avd_home.exists():
        return False
    return any(avd_home.glob("*.ini")) or any(avd_home.glob("*.avd"))


def resolve_runtime_layout(
    *,
    avd_home: str | None = None,
    emulator_home: str | None = None,
    datadir_root: str | None = None,
    log_dir: str | None = None,
    path_policy: str = PATH_POLICY_REPO_LOCAL,
) -> RuntimeLayout:
    env = dict(os.environ)
    resolved_avd_home: Path | None = None
    resolved_emulator_home: Path | None = None
    source = "default"

    if avd_home:
        resolved_avd_home = normalize_path(avd_home)
        resolved_emulator_home = normalize_path(emulator_home) if emulator_home else resolved_avd_home.parent
        source = "explicit"
    elif emulator_home:
        resolved_emulator_home = normalize_path(emulator_home)
        resolved_avd_home = resolved_emulator_home / "avd"
        source = "explicit"
    elif env.get("ANDROID_AVD_HOME") or env.get("ANDROID_EMULATOR_HOME"):
        if env.get("ANDROID_AVD_HOME"):
            resolved_avd_home = normalize_path(env["ANDROID_AVD_HOME"])
        if env.get("ANDROID_EMULATOR_HOME"):
            resolved_emulator_home = normalize_path(env["ANDROID_EMULATOR_HOME"])
        if resolved_avd_home is None and resolved_emulator_home is not None:
            resolved_avd_home = resolved_emulator_home / "avd"
        if resolved_emulator_home is None and resolved_avd_home is not None:
            resolved_emulator_home = resolved_avd_home.parent
        source = "environment"
    elif path_policy == PATH_POLICY_REPO_LOCAL and avd_home_has_definitions(WORKSPACE_AVD_HOME):
        resolved_emulator_home = WORKSPACE_EMULATOR_HOME
        resolved_avd_home = WORKSPACE_AVD_HOME
        source = "workspace"

    if resolved_emulator_home is not None:
        env["ANDROID_EMULATOR_HOME"] = str(resolved_emulator_home)
    if resolved_avd_home is not None:
        env["ANDROID_AVD_HOME"] = str(resolved_avd_home)

    if datadir_root:
        resolved_datadir_root = normalize_path(datadir_root)
    elif path_policy == PATH_POLICY_REPO_LOCAL:
        resolved_datadir_root = WORKSPACE_DATADIR_ROOT
    else:
        resolved_datadir_root = None

    resolved_log_dir = normalize_path(log_dir) if log_dir else WORKSPACE_LOG_DIR
    return RuntimeLayout(
        env=env,
        source=source,
        path_policy=path_policy,
        emulator_home=resolved_emulator_home,
        avd_home=resolved_avd_home,
        datadir_root=resolved_datadir_root,
        log_dir=resolved_log_dir,
    )


def describe_avd_home(layout: RuntimeLayout) -> str:
    if layout.avd_home is not None:
        return str(layout.avd_home)
    return str(DEFAULT_HOST_AVD_HOME)


def running_emulator_name(serial: str) -> str | None:
    result = command_output(adb_command(serial, "emu", "avd", "name"), check=False)
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    for line in reversed(output.splitlines()):
        stripped = line.strip()
        if stripped and stripped != "OK":
            return stripped
    return None


def resolve_serial(explicit_serial: str | None) -> str:
    if explicit_serial:
        return explicit_serial
    env_serial = os.environ.get("ANDROID_SERIAL")
    if env_serial:
        return env_serial
    active_devices = [device for device in list_devices() if device.state == "device"]
    if len(active_devices) == 1:
        return active_devices[0].serial
    if not active_devices:
        raise SystemExit("No connected Android device or emulator found. Start one or pass --serial.")
    raise SystemExit("Multiple Android devices are connected. Pass --serial or set ANDROID_SERIAL.")


def resolve_emulator_serial(explicit_serial: str | None, allow_all: bool = False) -> list[str]:
    devices = [device for device in list_devices() if device.state == "device" and device.is_emulator]
    if allow_all:
        return [device.serial for device in devices]
    serial = resolve_serial(explicit_serial)
    if not serial.startswith("emulator-"):
        raise SystemExit(f"Device {serial} is not an emulator.")
    return [serial]


def wait_for_boot(serial: str, timeout_seconds: float) -> None:
    command_output(adb_command(serial, "wait-for-device"), timeout=timeout_seconds)
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        boot_completed = command_output(adb_command(serial, "shell", "getprop", "sys.boot_completed"), check=False)
        bootanim_state = command_output(adb_command(serial, "shell", "getprop", "init.svc.bootanim"), check=False)
        boot_completed_value = str(boot_completed.stdout).strip()
        bootanim_value = str(bootanim_state.stdout).strip()
        if boot_completed_value == "1" and bootanim_value in {"", "stopped"}:
            command_output(adb_command(serial, "shell", "input", "keyevent", "82"), check=False)
            return
        time.sleep(POLL_INTERVAL_SECONDS)
    raise SystemExit(f"Timed out waiting for {serial} to finish booting.")


def wait_for_new_emulator(
    previous_serials: set[str],
    timeout_seconds: float,
    process: subprocess.Popen[bytes] | None = None,
) -> str:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        if process is not None and process.poll() is not None:
            raise SystemExit("Emulator process exited before appearing in adb devices.")
        for device in list_devices():
            if device.is_emulator and device.serial not in previous_serials:
                return device.serial
        time.sleep(POLL_INTERVAL_SECONDS)
    raise SystemExit("Timed out waiting for a new emulator to appear in adb devices.")


def disable_animations(serial: str) -> None:
    for setting in (
        "window_animation_scale",
        "transition_animation_scale",
        "animator_duration_scale",
    ):
        command_output(adb_command(serial, "shell", "settings", "put", "global", setting, "0"), check=False)


def tail_text(path: Path, max_lines: int = 20) -> str:
    if not path.exists():
        return ""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    return "\n".join(lines[-max_lines:])


def launch_emulator_process(command: Sequence[str], log_path: Path, env: dict[str, str]) -> subprocess.Popen[bytes]:
    launch_env = dict(env)
    launch_env.setdefault("ANDROID_EMU_ENABLE_CRASH_REPORTING", "0")
    with log_path.open("wb") as log_file:
        return subprocess.Popen(
            list(command),
            stdout=log_file,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            env=launch_env,
        )


def format_emulator_launch_failure(log_path: Path) -> str:
    details = tail_text(log_path)
    message = [
        "Timed out waiting for a new emulator to appear in adb devices.",
        f"emulator log: {log_path}",
    ]
    if details:
        message.append("recent emulator output:")
        message.append(details)
    return "\n".join(message)


def parse_badging_package_name(raw_output: str) -> str | None:
    match = PACKAGE_NAME_RE.search(raw_output)
    return match.group(1) if match else None


def parse_badging_launchable_activity(raw_output: str) -> str | None:
    match = LAUNCHABLE_ACTIVITY_RE.search(raw_output)
    return match.group(1) if match else None


def parse_resolve_activity(raw_output: str) -> str | None:
    for line in reversed(raw_output.splitlines()):
        stripped = line.strip()
        if not stripped or stripped.startswith("priority=") or stripped.startswith("name="):
            continue
        if stripped in {"No activity found", "no activities found"}:
            return None
        if "/" in stripped:
            return stripped
    return None


def normalize_component(package_name: str, activity_name: str) -> str:
    if "/" in activity_name:
        return activity_name
    return f"{package_name}/{activity_name}"


def parse_am_start_error(raw_output: str) -> str | None:
    error_lines = [
        line.strip()
        for line in raw_output.splitlines()
        if line.strip().startswith(ACTIVITY_START_ERROR_PREFIXES)
    ]
    if not error_lines:
        return None
    return "\n".join(error_lines)


def parse_monkey_error(raw_output: str) -> str | None:
    for line in raw_output.splitlines():
        stripped = line.strip()
        if "No activities found" in stripped or "monkey aborted" in stripped:
            return stripped
    return None


def parse_status_failure(raw_output: str) -> str | None:
    for line in raw_output.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("Failure") or stripped.startswith("Failed") or stripped.startswith("Unknown package:"):
            return stripped
    return None


def apk_metadata_from_badging(raw_output: str) -> ApkMetadata:
    return ApkMetadata(
        package_name=parse_badging_package_name(raw_output),
        launchable_activity=parse_badging_launchable_activity(raw_output),
    )


def inspect_apk(apk_path: Path) -> ApkMetadata:
    package_name: str | None = None
    launchable_activity: str | None = None
    apkanalyzer = resolve_apkanalyzer()
    if apkanalyzer:
        result = command_output([apkanalyzer, "manifest", "application-id", str(apk_path)], check=False)
        output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
        value = output.strip()
        if value and "ERROR:" not in value:
            package_name = value.splitlines()[-1].strip()
    aapt = resolve_aapt()
    if aapt:
        result = command_output([aapt, "dump", "badging", str(apk_path)], check=False)
        output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
        metadata = apk_metadata_from_badging(output)
        package_name = package_name or metadata.package_name
        launchable_activity = metadata.launchable_activity
    return ApkMetadata(package_name=package_name, launchable_activity=launchable_activity)


def resolve_launch_component(serial: str, package_name: str) -> str | None:
    result = command_output(
        adb_command(serial, "shell", "cmd", "package", "resolve-activity", "--brief", package_name),
        check=False,
    )
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    component = parse_resolve_activity(output)
    if not component:
        return None
    if component.startswith(package_name + "/"):
        return component
    if component.startswith("."):
        return f"{package_name}/{component}"
    return component


def resolve_package_pid(serial: str, package_name: str) -> str | None:
    result = command_output(adb_command(serial, "shell", "pidof", "-s", package_name), check=False)
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    value = output.strip()
    return value if value else None


def perform_install(
    serial: str,
    apk_path: Path,
    *,
    grant_all_permissions: bool,
    allow_test_apks: bool,
    allow_downgrade: bool,
) -> tuple[ApkMetadata, str]:
    if not apk_path.exists():
        raise SystemExit(f"APK not found: {apk_path}")
    command = adb_command(serial, "install", "-r")
    if grant_all_permissions:
        command.append("-g")
    if allow_test_apks:
        command.append("-t")
    if allow_downgrade:
        command.append("-d")
    command.append(str(apk_path))
    result = command_output(command)
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    failure = parse_status_failure(output)
    if failure:
        raise SystemExit(f"Failed to install {apk_path}.\n{output.strip()}")
    return inspect_apk(apk_path), output.strip()


def perform_run(
    serial: str,
    *,
    package: str | None,
    apk: str | None,
    activity: str | None,
    stop_before_start: bool,
    no_wait: bool,
) -> str:
    apk_metadata = ApkMetadata(package_name=None, launchable_activity=None)
    if apk:
        apk_path = Path(apk)
        if not apk_path.exists():
            raise SystemExit(f"APK not found: {apk_path}")
        apk_metadata = inspect_apk(apk_path)
    package_name = package or apk_metadata.package_name
    if not package_name:
        raise SystemExit("Provide --package or --apk with readable package metadata.")
    activity_name = activity or apk_metadata.launchable_activity
    if stop_before_start:
        command_output(adb_command(serial, "shell", "am", "force-stop", package_name), check=False)
    component = normalize_component(package_name, activity_name) if activity_name else resolve_launch_component(serial, package_name)
    if component:
        command = adb_command(serial, "shell", "am", "start")
        if not no_wait:
            command.append("-W")
        command.extend(["-n", component])
        result = command_output(command)
        output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
        error = parse_am_start_error(output)
        if error:
            raise SystemExit(f"Failed to start {component}.\n{output.strip()}")
        return f"started {component}"
    result = command_output(
        adb_command(
            serial,
            "shell",
            "monkey",
            "-p",
            package_name,
            "-c",
            "android.intent.category.LAUNCHER",
            "1",
        )
    )
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    error = parse_monkey_error(output)
    if error:
        raise SystemExit(f"Failed to start {package_name} via monkey launcher fallback.\n{output.strip()}")
    return f"started {package_name} via monkey launcher fallback"


def perform_uninstall(serial: str, package_name: str) -> str:
    result = command_output(adb_command(serial, "uninstall", package_name), check=False)
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    failure = parse_status_failure(output)
    if failure:
        raise SystemExit(f"Failed to uninstall {package_name}.\n{output.strip()}")
    return output.strip() or "Success"


def perform_clear_data(serial: str, package_name: str) -> str:
    result = command_output(adb_command(serial, "shell", "pm", "clear", package_name), check=False)
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    failure = parse_status_failure(output)
    if failure:
        raise SystemExit(f"Failed to clear data for {package_name}.\n{output.strip()}")
    return output.strip() or "Success"


def device_record(device: Device, include_avd_name: bool = False) -> dict[str, Any]:
    record: dict[str, Any] = {
        "serial": device.serial,
        "state": device.state,
        "is_emulator": device.is_emulator,
        "details": dict(device.details),
    }
    if include_avd_name and device.is_emulator and device.state == "device":
        record["avd_name"] = running_emulator_name(device.serial)
    return record


def layout_record(layout: RuntimeLayout) -> dict[str, Any]:
    return {
        "source": layout.source,
        "path_policy": layout.path_policy,
        "android_emulator_home": str(layout.emulator_home) if layout.emulator_home is not None else None,
        "android_avd_home": describe_avd_home(layout),
        "datadir_root": str(layout.datadir_root) if layout.datadir_root is not None else None,
        "log_dir": str(layout.log_dir),
    }


def print_json(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, indent=2, sort_keys=True))


def command_doctor(args: argparse.Namespace) -> int:
    layout = resolve_runtime_layout(
        avd_home=args.avd_home,
        emulator_home=args.emulator_home,
        datadir_root=args.datadir_root,
        log_dir=args.log_dir,
        path_policy=args.path_policy,
    )
    adb = resolve_adb()
    emulator = resolve_emulator()
    aapt = resolve_aapt()
    apkanalyzer = resolve_apkanalyzer()
    avds = list_avds(layout.env)
    devices = list_devices()
    if args.json:
        print_json(
            {
                "tools": {"adb": adb, "emulator": emulator, "aapt": aapt, "apkanalyzer": apkanalyzer},
                "layout": layout_record(layout),
                "available_avds": avds,
                "devices": [device_record(device, include_avd_name=True) for device in devices],
            }
        )
        return 0
    print(f"adb: {adb}")
    print(f"emulator: {emulator}")
    print(f"aapt: {aapt or '(not found)'}")
    print(f"apkanalyzer: {apkanalyzer or '(not found)'}")
    print(f"avd source: {layout.source}")
    print(f"path policy: {layout.path_policy}")
    print(f"android_emulator_home: {layout.emulator_home or '(default host location)'}")
    print(f"android_avd_home: {describe_avd_home(layout)}")
    print(f"datadir root: {layout.datadir_root or '(emulator default)'}")
    print(f"log dir: {layout.log_dir}")
    print("available avds:")
    if avds:
        for avd in avds:
            print(f"  - {avd}")
    else:
        print("  (none)")
    print("connected devices:")
    if devices:
        for device in devices:
            extra = []
            if device.is_emulator and device.state == "device":
                avd_name = running_emulator_name(device.serial)
                if avd_name:
                    extra.append(f"avd={avd_name}")
            model = device.details.get("model")
            if model:
                extra.append(f"model={model}")
            suffix = f" ({', '.join(extra)})" if extra else ""
            print(f"  - {device.serial} [{device.state}]{suffix}")
    else:
        print("  (none)")
    return 0


def command_devices(args: argparse.Namespace) -> int:
    devices = list_devices()
    if args.json:
        print_json({"devices": [device_record(device, include_avd_name=True) for device in devices]})
        return 0
    if not devices:
        print("(none)")
        return 0
    for device in devices:
        extra = []
        if device.is_emulator and device.state == "device":
            avd_name = running_emulator_name(device.serial)
            if avd_name:
                extra.append(f"avd={avd_name}")
        model = device.details.get("model")
        if model:
            extra.append(f"model={model}")
        suffix = f" ({', '.join(extra)})" if extra else ""
        print(f"{device.serial} [{device.state}]{suffix}")
    return 0


def command_list_avds(args: argparse.Namespace) -> int:
    layout = resolve_runtime_layout(
        avd_home=args.avd_home,
        emulator_home=args.emulator_home,
        datadir_root=args.datadir_root,
        log_dir=args.log_dir,
        path_policy=args.path_policy,
    )
    avds = list_avds(layout.env)
    if args.json:
        print_json({"layout": layout_record(layout), "available_avds": avds})
        return 0
    if not avds:
        print("(none)")
        return 0
    for avd in avds:
        print(avd)
    return 0


def command_boot(args: argparse.Namespace) -> int:
    layout = resolve_runtime_layout(
        avd_home=args.avd_home,
        emulator_home=args.emulator_home,
        datadir_root=args.datadir_root,
        log_dir=args.log_dir,
        path_policy=args.path_policy,
    )
    avds = list_avds(layout.env)
    if not avds:
        raise SystemExit("No AVDs are available in the selected AVD home. Create one there or pass --avd-home/--emulator-home.")
    avd = args.avd or avds[0]
    if avd not in avds:
        raise SystemExit(f"AVD '{avd}' was not found. Available AVDs: {', '.join(avds)}")
    for device in list_devices():
        if device.is_emulator and device.state == "device" and running_emulator_name(device.serial) == avd:
            wait_for_boot(device.serial, args.boot_timeout)
            if args.disable_animations:
                disable_animations(device.serial)
            print(device.serial)
            return 0
    base_command = [resolve_emulator(), f"@{avd}", "-netdelay", "none", "-netspeed", "full", "-no-boot-anim"]
    if args.headless:
        base_command.append("-no-window")
    if not args.save_snapshot_on_exit:
        base_command.append("-no-snapshot-save")
    if args.wipe_data:
        base_command.append("-wipe-data")
    if args.gpu:
        base_command.extend(["-gpu", args.gpu])
    if layout.datadir_root is not None:
        datadir = layout.datadir_root / avd
        datadir.mkdir(parents=True, exist_ok=True)
        base_command.extend(["-datadir", str(datadir)])
    layout.log_dir.mkdir(parents=True, exist_ok=True)
    safe_avd_name = avd.replace("/", "_")
    for attempt in range(1, EMULATOR_LAUNCH_ATTEMPTS + 1):
        previous_serials = {device.serial for device in list_devices()}
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        log_path = layout.log_dir / f"emulator-{safe_avd_name}-{timestamp}-attempt{attempt}.log"
        command = list(base_command)
        if args.cold or attempt > 1:
            command.append("-no-snapshot-load")
        process = launch_emulator_process(command, log_path, layout.env)
        try:
            serial = wait_for_new_emulator(previous_serials, args.launch_timeout, process)
            break
        except SystemExit as exc:
            if process.poll() is not None:
                if attempt < EMULATOR_LAUNCH_ATTEMPTS:
                    time.sleep(EMULATOR_LAUNCH_RETRY_DELAY_SECONDS)
                    continue
                raise SystemExit(format_emulator_launch_failure(log_path)) from exc
            raise
    else:
        raise SystemExit("Failed to launch the Android emulator.")
    wait_for_boot(serial, args.boot_timeout)
    if args.disable_animations:
        disable_animations(serial)
    print(serial)
    return 0


def command_install(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    metadata, output = perform_install(
        serial,
        Path(args.apk),
        grant_all_permissions=args.grant_all_permissions,
        allow_test_apks=args.allow_test_apks,
        allow_downgrade=args.allow_downgrade,
    )
    suffix = f" package={metadata.package_name}" if metadata.package_name else ""
    print(f"installed {args.apk}{suffix}")
    if output:
        print(output)
    return 0


def command_deploy(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    metadata, output = perform_install(
        serial,
        Path(args.apk),
        grant_all_permissions=args.grant_all_permissions,
        allow_test_apks=args.allow_test_apks,
        allow_downgrade=args.allow_downgrade,
    )
    suffix = f" package={metadata.package_name}" if metadata.package_name else ""
    print(f"installed {args.apk}{suffix}")
    if output:
        print(output)
    if args.no_run:
        return 0
    print(
        perform_run(
            serial,
            package=args.package,
            apk=args.apk,
            activity=args.activity,
            stop_before_start=args.stop_before_start,
            no_wait=args.no_wait,
        )
    )
    return 0


def command_run(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    print(
        perform_run(
            serial,
            package=args.package,
            apk=args.apk,
            activity=args.activity,
            stop_before_start=args.stop_before_start,
            no_wait=args.no_wait,
        )
    )
    return 0


def command_uninstall(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    output = perform_uninstall(serial, args.package)
    print(f"uninstalled {args.package}")
    if output:
        print(output)
    return 0


def command_stop_app(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    command_output(adb_command(serial, "shell", "am", "force-stop", args.package), check=False)
    print(f"stopped {args.package}")
    return 0


def command_clear_data(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    output = perform_clear_data(serial, args.package)
    print(f"cleared data for {args.package}")
    if output:
        print(output)
    return 0


def command_shutdown(args: argparse.Namespace) -> int:
    targets = resolve_emulator_serial(args.serial, allow_all=args.all)
    if not targets:
        raise SystemExit("No running emulators found.")
    for serial in targets:
        command_output(adb_command(serial, "emu", "kill"), check=False)
        print(f"stopped {serial}")
    return 0


def command_logs(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    if args.clear:
        command_output(adb_command(serial, "logcat", "-c"), check=False)
        print(f"cleared logcat on {serial}")
        return 0
    command = adb_command(serial, "logcat")
    if args.lines is not None:
        command.extend(["-t", str(args.lines)])
    if args.dump:
        command.append("-d")
    if args.package:
        pid = resolve_package_pid(serial, args.package)
        if not pid:
            raise SystemExit(f"Package {args.package} is not running on {serial}; unable to filter logcat by PID.")
        command.extend(["--pid", pid])
    for filter_spec in args.filter_spec:
        command.append(filter_spec)
    if args.dump:
        result = command_output(command)
        output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
        if output.strip():
            print(output.strip())
        return 0
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as exc:
        raise SystemExit(f"Command failed: {' '.join(command)}") from exc
    return 0


def add_common_serial_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--serial", help="adb device serial. Defaults to ANDROID_SERIAL or the sole connected device.")


def add_layout_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--path-policy", choices=[PATH_POLICY_REPO_LOCAL, PATH_POLICY_HOST_DEFAULT], default=PATH_POLICY_REPO_LOCAL)
    parser.add_argument("--avd-home", help="Directory containing AVD definitions.")
    parser.add_argument("--emulator-home", help="Android emulator home directory.")
    parser.add_argument("--datadir-root", help="Root directory for emulator writable runtime data.")
    parser.add_argument("--log-dir", help="Directory for emulator launch logs.")


def add_install_arguments(parser: argparse.ArgumentParser) -> None:
    add_common_serial_argument(parser)
    parser.add_argument("--apk", required=True)
    parser.add_argument("--grant-all-permissions", action="store_true")
    parser.add_argument("--allow-test-apks", action="store_true")
    parser.add_argument("--allow-downgrade", action="store_true")


def add_run_arguments(parser: argparse.ArgumentParser) -> None:
    add_common_serial_argument(parser)
    source_group = parser.add_mutually_exclusive_group(required=True)
    source_group.add_argument("--package")
    source_group.add_argument("--apk")
    parser.add_argument("--activity")
    parser.add_argument("--stop-before-start", action="store_true")
    parser.add_argument("--no-wait", action="store_true")


def add_json_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--json", action="store_true")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Android emulator and device deploy/run helper.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    doctor_parser = subparsers.add_parser("doctor", help="Show Android tool resolution, layout, AVDs, and devices.")
    add_layout_arguments(doctor_parser)
    add_json_argument(doctor_parser)
    doctor_parser.set_defaults(func=command_doctor)

    devices_parser = subparsers.add_parser("devices", help="List connected Android devices and emulators.")
    add_json_argument(devices_parser)
    devices_parser.set_defaults(func=command_devices)

    avds_parser = subparsers.add_parser("list-avds", help="List available AVDs for the selected layout.")
    add_layout_arguments(avds_parser)
    add_json_argument(avds_parser)
    avds_parser.set_defaults(func=command_list_avds)

    boot_parser = subparsers.add_parser("boot", help="Boot or reuse an Android emulator and wait until it is ready.")
    add_layout_arguments(boot_parser)
    boot_parser.add_argument("--avd")
    boot_parser.add_argument("--headless", action="store_true")
    boot_parser.add_argument("--cold", action="store_true")
    boot_parser.add_argument("--wipe-data", action="store_true")
    boot_parser.add_argument("--disable-animations", action="store_true")
    boot_parser.add_argument("--save-snapshot-on-exit", action="store_true")
    boot_parser.add_argument("--launch-timeout", type=float, default=60.0)
    boot_parser.add_argument("--boot-timeout", type=float, default=180.0)
    boot_parser.add_argument("--gpu", default="swiftshader_indirect")
    boot_parser.set_defaults(func=command_boot)

    install_parser = subparsers.add_parser("install", aliases=["install-apk"], help="Install an APK onto the selected device.")
    add_install_arguments(install_parser)
    install_parser.set_defaults(func=command_install)

    deploy_parser = subparsers.add_parser("deploy", help="Install an APK and run it unless --no-run is provided.")
    add_install_arguments(deploy_parser)
    deploy_parser.add_argument("--package")
    deploy_parser.add_argument("--activity")
    deploy_parser.add_argument("--stop-before-start", action="store_true")
    deploy_parser.add_argument("--no-wait", action="store_true")
    deploy_parser.add_argument("--no-run", action="store_true")
    deploy_parser.set_defaults(func=command_deploy)

    run_parser = subparsers.add_parser("run", aliases=["start-app"], help="Start an app from package name or APK metadata.")
    add_run_arguments(run_parser)
    run_parser.set_defaults(func=command_run)

    uninstall_parser = subparsers.add_parser("uninstall", help="Uninstall an app package from the selected device.")
    add_common_serial_argument(uninstall_parser)
    uninstall_parser.add_argument("--package", required=True)
    uninstall_parser.set_defaults(func=command_uninstall)

    stop_parser = subparsers.add_parser("stop-app", help="Force-stop an app package.")
    add_common_serial_argument(stop_parser)
    stop_parser.add_argument("--package", required=True)
    stop_parser.set_defaults(func=command_stop_app)

    clear_parser = subparsers.add_parser("clear-data", help="Clear app data for a package.")
    add_common_serial_argument(clear_parser)
    clear_parser.add_argument("--package", required=True)
    clear_parser.set_defaults(func=command_clear_data)

    shutdown_parser = subparsers.add_parser("shutdown", help="Shut down one emulator or all running emulators.")
    add_common_serial_argument(shutdown_parser)
    shutdown_parser.add_argument("--all", action="store_true")
    shutdown_parser.set_defaults(func=command_shutdown)

    logs_parser = subparsers.add_parser("logs", help="Inspect or stream logcat on the selected device.")
    add_common_serial_argument(logs_parser)
    logs_parser.add_argument("--package")
    logs_parser.add_argument("--clear", action="store_true")
    logs_parser.add_argument("--dump", action="store_true")
    logs_parser.add_argument("--lines", type=int)
    logs_parser.add_argument("--filter-spec", action="append", default=[])
    logs_parser.set_defaults(func=command_logs)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
