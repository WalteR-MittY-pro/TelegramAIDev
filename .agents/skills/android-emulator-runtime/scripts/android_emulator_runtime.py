#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

POLL_INTERVAL_SECONDS = 0.5
EMULATOR_LAUNCH_ATTEMPTS = 3
EMULATOR_LAUNCH_RETRY_DELAY_SECONDS = 5.0
DEFAULT_HOST_AVD_HOME = Path.home() / ".android" / "avd"
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
class EmulatorStorage:
    env: dict[str, str]
    source: str
    emulator_home: Path | None
    avd_home: Path | None
    datadir_root: Path


def resolve_repo_root() -> Path:
    script_path = Path(__file__).resolve()
    for parent in script_path.parents:
        if (parent / ".agents").exists() and (parent / "AGENTS.md").exists():
            return parent
    return script_path.parents[4]


REPO_ROOT = resolve_repo_root()
WORKSPACE_EMULATOR_HOME = REPO_ROOT / ".cache" / "android-avd-home"
WORKSPACE_AVD_HOME = WORKSPACE_EMULATOR_HOME / "avd"
WORKSPACE_DATADIR_ROOT = REPO_ROOT / ".cache" / "android-avd-data"


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


def resolve_adb() -> str:
    adb = shutil.which("adb")
    if not adb:
        raise SystemExit("Unable to find adb in PATH.")
    return adb


def resolve_emulator() -> str:
    candidates: list[Path] = []
    sdk_root = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    if sdk_root:
        candidates.append(Path(sdk_root) / "emulator" / "emulator")
    adb_path = shutil.which("adb")
    if adb_path:
        candidates.append(Path(adb_path).resolve().parents[1] / "emulator" / "emulator")
    emulator_path = shutil.which("emulator")
    if emulator_path:
        candidates.append(Path(emulator_path))
    for candidate in candidates:
        if candidate.exists():
            return str(candidate)
    raise SystemExit("Unable to find the Android emulator binary.")


def resolve_aapt() -> str | None:
    sdk_root = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    candidates: list[Path] = []
    if sdk_root:
        build_tools_dir = Path(sdk_root) / "build-tools"
        if build_tools_dir.exists():
            for child in sorted(build_tools_dir.iterdir(), reverse=True):
                candidates.append(child / "aapt")
    aapt_path = shutil.which("aapt")
    if aapt_path:
        candidates.append(Path(aapt_path))
    for candidate in candidates:
        if candidate.exists():
            return str(candidate)
    return None


def resolve_apkanalyzer() -> str | None:
    sdk_root = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    candidates: list[Path] = []
    if sdk_root:
        candidates.extend(
            [
                Path(sdk_root) / "cmdline-tools" / "latest" / "bin" / "apkanalyzer",
                Path(sdk_root) / "tools" / "bin" / "apkanalyzer",
            ]
        )
    apkanalyzer_path = shutil.which("apkanalyzer")
    if apkanalyzer_path:
        candidates.append(Path(apkanalyzer_path))
    for candidate in candidates:
        if candidate.exists():
            return str(candidate)
    return None


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


def normalize_path(raw_path: str) -> Path:
    return Path(raw_path).expanduser().resolve()


def avd_home_has_definitions(avd_home: Path) -> bool:
    if not avd_home.exists():
        return False
    return any(avd_home.glob("*.ini")) or any(avd_home.glob("*.avd"))


def resolve_emulator_storage(
    avd_home: str | None = None,
    emulator_home: str | None = None,
    datadir_root: str | None = None,
) -> EmulatorStorage:
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
    elif avd_home_has_definitions(WORKSPACE_AVD_HOME):
        resolved_emulator_home = WORKSPACE_EMULATOR_HOME
        resolved_avd_home = WORKSPACE_AVD_HOME
        source = "workspace"

    if resolved_emulator_home is not None:
        env["ANDROID_EMULATOR_HOME"] = str(resolved_emulator_home)
    if resolved_avd_home is not None:
        env["ANDROID_AVD_HOME"] = str(resolved_avd_home)

    resolved_datadir_root = normalize_path(datadir_root) if datadir_root else WORKSPACE_DATADIR_ROOT
    return EmulatorStorage(
        env=env,
        source=source,
        emulator_home=resolved_emulator_home,
        avd_home=resolved_avd_home,
        datadir_root=resolved_datadir_root,
    )


def describe_avd_home(storage: EmulatorStorage) -> str:
    if storage.avd_home is not None:
        return str(storage.avd_home)
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
    env = dict(env)
    env.setdefault("ANDROID_EMU_ENABLE_CRASH_REPORTING", "0")
    with log_path.open("wb") as log_file:
        return subprocess.Popen(
            command,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            env=env,
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


def command_doctor(args: argparse.Namespace) -> int:
    storage = resolve_emulator_storage(args.avd_home, args.emulator_home, args.datadir_root)
    adb = resolve_adb()
    emulator = resolve_emulator()
    aapt = resolve_aapt() or "(not found)"
    apkanalyzer = resolve_apkanalyzer() or "(not found)"
    print(f"adb: {adb}")
    print(f"emulator: {emulator}")
    print(f"aapt: {aapt}")
    print(f"apkanalyzer: {apkanalyzer}")
    print(f"avd source: {storage.source}")
    print(f"android_emulator_home: {storage.emulator_home or '(default host location)'}")
    print(f"android_avd_home: {describe_avd_home(storage)}")
    print(f"datadir root: {storage.datadir_root}")
    print("available avds:")
    avds = list_avds(storage.env)
    if avds:
        for avd in avds:
            print(f"  - {avd}")
    else:
        print("  (none)")
    print("connected devices:")
    devices = list_devices()
    if devices:
        for device in devices:
            extra = []
            if device.is_emulator:
                avd_name = running_emulator_name(device.serial)
                if avd_name:
                    extra.append(f"avd={avd_name}")
            model = device.details.get("model")
            if model:
                extra.append(f"model={model}")
            detail_suffix = f" ({', '.join(extra)})" if extra else ""
            print(f"  - {device.serial} [{device.state}]{detail_suffix}")
    else:
        print("  (none)")
    return 0


def command_boot(args: argparse.Namespace) -> int:
    storage = resolve_emulator_storage(args.avd_home, args.emulator_home, args.datadir_root)
    avds = list_avds(storage.env)
    if not avds:
        raise SystemExit(
            "No AVDs are available in the selected AVD home. Create one there or pass --avd-home/--emulator-home."
        )
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

    base_command = [
        resolve_emulator(),
        f"@{avd}",
        "-netdelay",
        "none",
        "-netspeed",
        "full",
        "-no-boot-anim",
    ]
    if args.headless:
        base_command.append("-no-window")
    if not args.save_snapshot_on_exit:
        base_command.append("-no-snapshot-save")
    if args.wipe_data:
        base_command.append("-wipe-data")
    if args.gpu:
        base_command.extend(["-gpu", args.gpu])
    datadir = storage.datadir_root / avd
    datadir.mkdir(parents=True, exist_ok=True)
    base_command.extend(["-datadir", str(datadir)])

    log_dir = Path.cwd() / ".cache" / "android-emulator-runtime"
    log_dir.mkdir(parents=True, exist_ok=True)
    safe_avd_name = avd.replace("/", "_")

    for attempt in range(1, EMULATOR_LAUNCH_ATTEMPTS + 1):
        previous_serials = {device.serial for device in list_devices()}
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        log_path = log_dir / f"emulator-{safe_avd_name}-{timestamp}-attempt{attempt}.log"
        command = list(base_command)
        if args.cold or attempt > 1:
            command.append("-no-snapshot-load")
        process = launch_emulator_process(command, log_path, storage.env)

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


def command_install_apk(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    apk_path = Path(args.apk)
    if not apk_path.exists():
        raise SystemExit(f"APK not found: {apk_path}")

    command = adb_command(serial, "install", "-r")
    if args.grant_all_permissions:
        command.append("-g")
    if args.allow_test_apks:
        command.append("-t")
    if args.allow_downgrade:
        command.append("-d")
    command.append(str(apk_path))

    result = command_output(command)
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    metadata = inspect_apk(apk_path)
    package_suffix = f" package={metadata.package_name}" if metadata.package_name else ""
    print(f"installed {apk_path}{package_suffix}")
    if output.strip():
        print(output.strip())
    return 0


def command_start_app(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)

    apk_metadata = ApkMetadata(package_name=None, launchable_activity=None)
    if args.apk:
        apk_path = Path(args.apk)
        if not apk_path.exists():
            raise SystemExit(f"APK not found: {apk_path}")
        apk_metadata = inspect_apk(apk_path)

    package_name = args.package or apk_metadata.package_name
    if not package_name:
        raise SystemExit("Provide --package or --apk with readable package metadata.")

    activity_name = args.activity or apk_metadata.launchable_activity
    if args.stop_before_start:
        command_output(adb_command(serial, "shell", "am", "force-stop", package_name), check=False)

    if activity_name:
        component = normalize_component(package_name, activity_name)
    else:
        component = resolve_launch_component(serial, package_name)

    if component:
        command = adb_command(serial, "shell", "am", "start")
        if not args.no_wait:
            command.append("-W")
        command.extend(["-n", component])
        result = command_output(command)
        output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
        error = parse_am_start_error(output)
        if error:
            raise SystemExit(f"Failed to start {component}.\n{output.strip()}")
        print(f"started {component}")
        return 0

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
    print(f"started {package_name} via monkey launcher fallback")
    return 0


def add_common_serial_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--serial", help="adb device serial. Defaults to ANDROID_SERIAL or the sole connected device.")


def add_emulator_storage_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--avd-home",
        help="Directory containing AVD definitions. Defaults to ANDROID_AVD_HOME, then a workspace-local .cache path if available.",
    )
    parser.add_argument(
        "--emulator-home",
        help="Android emulator home directory. Defaults to ANDROID_EMULATOR_HOME or the parent of --avd-home.",
    )
    parser.add_argument(
        "--datadir-root",
        help="Root directory for emulator writable runtime data. Defaults to a workspace-local .cache path.",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Small adb/emulator helper for Android runtime setup.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    doctor_parser = subparsers.add_parser("doctor", help="Show adb/emulator paths, APK tools, AVDs, and connected devices.")
    add_emulator_storage_arguments(doctor_parser)
    doctor_parser.set_defaults(func=command_doctor)

    boot_parser = subparsers.add_parser("boot", help="Boot or reuse an Android emulator and wait until Android is ready.")
    add_emulator_storage_arguments(boot_parser)
    boot_parser.add_argument("--avd", help="AVD name. Defaults to the first listed AVD.")
    boot_parser.add_argument("--headless", action="store_true", help="Use -no-window.")
    boot_parser.add_argument("--cold", action="store_true", help="Use -no-snapshot-load.")
    boot_parser.add_argument("--wipe-data", action="store_true", help="Use -wipe-data.")
    boot_parser.add_argument("--disable-animations", action="store_true", help="Set emulator animation scales to 0 after boot.")
    boot_parser.add_argument(
        "--save-snapshot-on-exit",
        action="store_true",
        help="Allow the emulator to save snapshot state on exit. By default this helper passes -no-snapshot-save.",
    )
    boot_parser.add_argument("--launch-timeout", type=float, default=60.0)
    boot_parser.add_argument("--boot-timeout", type=float, default=180.0)
    boot_parser.add_argument("--gpu", default="swiftshader_indirect", help="Passed to emulator -gpu.")
    boot_parser.set_defaults(func=command_boot)

    install_parser = subparsers.add_parser("install-apk", help="Install an APK onto the selected device.")
    add_common_serial_argument(install_parser)
    install_parser.add_argument("--apk", required=True)
    install_parser.add_argument("--grant-all-permissions", action="store_true")
    install_parser.add_argument("--allow-test-apks", action="store_true")
    install_parser.add_argument("--allow-downgrade", action="store_true")
    install_parser.set_defaults(func=command_install_apk)

    start_parser = subparsers.add_parser("start-app", help="Start an app from package name or APK metadata.")
    add_common_serial_argument(start_parser)
    source_group = start_parser.add_mutually_exclusive_group(required=True)
    source_group.add_argument("--package")
    source_group.add_argument("--apk")
    start_parser.add_argument("--activity", help="Explicit activity name, for example .MainActivity.")
    start_parser.add_argument("--stop-before-start", action="store_true")
    start_parser.add_argument("--no-wait", action="store_true")
    start_parser.set_defaults(func=command_start_app)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
