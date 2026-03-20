#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

BOUNDS_RE = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")
POLL_INTERVAL_SECONDS = 0.5
EMULATOR_LAUNCH_ATTEMPTS = 3
EMULATOR_LAUNCH_RETRY_DELAY_SECONDS = 5.0


@dataclass(frozen=True)
class Device:
    serial: str
    state: str
    details: dict[str, str]

    @property
    def is_emulator(self) -> bool:
        return self.serial.startswith("emulator-")


@dataclass(frozen=True)
class UiNode:
    index: int
    text: str
    resource_id: str
    content_desc: str
    class_name: str
    package: str
    clickable: bool
    enabled: bool
    bounds: tuple[int, int, int, int]

    @property
    def center(self) -> tuple[int, int]:
        left, top, right, bottom = self.bounds
        return ((left + right) // 2, (top + bottom) // 2)


@dataclass(frozen=True)
class Selector:
    text: str | None = None
    text_contains: str | None = None
    resource_id: str | None = None
    resource_id_contains: str | None = None
    content_desc: str | None = None
    content_desc_contains: str | None = None
    class_name: str | None = None
    package: str | None = None
    clickable: bool | None = None
    enabled: bool | None = None

    def matches(self, node: UiNode) -> bool:
        return all(
            (
                self.text is None or node.text == self.text,
                self.text_contains is None or self.text_contains in node.text,
                self.resource_id is None or node.resource_id == self.resource_id,
                self.resource_id_contains is None
                or self.resource_id_contains in node.resource_id,
                self.content_desc is None or node.content_desc == self.content_desc,
                self.content_desc_contains is None
                or self.content_desc_contains in node.content_desc,
                self.class_name is None or node.class_name == self.class_name,
                self.package is None or node.package == self.package,
                self.clickable is None or node.clickable == self.clickable,
                self.enabled is None or node.enabled == self.enabled,
            )
        )

    def describe(self) -> str:
        parts: list[str] = []
        for key, value in (
            ("text", self.text),
            ("text contains", self.text_contains),
            ("resource-id", self.resource_id),
            ("resource-id contains", self.resource_id_contains),
            ("content-desc", self.content_desc),
            ("content-desc contains", self.content_desc_contains),
            ("class", self.class_name),
            ("package", self.package),
            ("clickable", self.clickable),
            ("enabled", self.enabled),
        ):
            if value is not None:
                parts.append(f"{key}={value}")
        return ", ".join(parts) if parts else "no selector"


def command_output(
    command: Sequence[str],
    *,
    text: bool = True,
    check: bool = True,
    timeout: float | None = None,
) -> subprocess.CompletedProcess[str] | subprocess.CompletedProcess[bytes]:
    try:
        return subprocess.run(
            list(command),
            capture_output=True,
            text=text,
            check=check,
            timeout=timeout,
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


def list_avds() -> list[str]:
    result = command_output([resolve_emulator(), "-list-avds"])
    assert isinstance(result.stdout, str)
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


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
    raise SystemExit(
        "Multiple Android devices are connected. Pass --serial or set ANDROID_SERIAL."
    )


def parse_bounds(raw_bounds: str) -> tuple[int, int, int, int]:
    match = BOUNDS_RE.fullmatch(raw_bounds)
    if not match:
        raise ValueError(f"Unsupported bounds format: {raw_bounds}")
    return tuple(int(group) for group in match.groups())  # type: ignore[return-value]


def parse_ui_nodes(xml_text: str) -> list[UiNode]:
    root = ET.fromstring(xml_text)
    nodes: list[UiNode] = []
    for element in root.iter("node"):
        nodes.append(
            UiNode(
                index=int(element.attrib.get("index", "0")),
                text=element.attrib.get("text", ""),
                resource_id=element.attrib.get("resource-id", ""),
                content_desc=element.attrib.get("content-desc", ""),
                class_name=element.attrib.get("class", ""),
                package=element.attrib.get("package", ""),
                clickable=element.attrib.get("clickable", "false") == "true",
                enabled=element.attrib.get("enabled", "false") == "true",
                bounds=parse_bounds(element.attrib["bounds"]),
            )
        )
    return nodes


def selector_from_args(args: argparse.Namespace) -> Selector:
    return Selector(
        text=args.text,
        text_contains=args.text_contains,
        resource_id=args.resource_id,
        resource_id_contains=args.resource_id_contains,
        content_desc=args.content_desc,
        content_desc_contains=args.content_desc_contains,
        class_name=args.class_name,
        package=args.package,
        clickable=True if args.clickable else None,
        enabled=True if args.enabled else None,
    )


def ensure_selector(selector: Selector) -> None:
    if selector.describe() == "no selector":
        raise SystemExit(
            "Provide at least one selector such as --text, --text-contains, --resource-id, or --content-desc."
        )


def filter_nodes(nodes: Iterable[UiNode], selector: Selector) -> list[UiNode]:
    return [node for node in nodes if selector.matches(node)]


def format_node(node: UiNode, ordinal: int | None = None) -> str:
    prefix = f"[{ordinal}] " if ordinal is not None else ""
    center_x, center_y = node.center
    return (
        f'{prefix}text="{node.text}" '
        f'desc="{node.content_desc}" '
        f'resource_id="{node.resource_id}" '
        f'class="{node.class_name}" '
        f"clickable={node.clickable} "
        f"enabled={node.enabled} "
        f"bounds={node.bounds} "
        f"center=({center_x},{center_y})"
    )


def fetch_ui_xml(serial: str) -> str:
    remote_path = "/sdcard/window_dump.xml"
    command_output(adb_command(serial, "shell", "uiautomator", "dump", remote_path), check=False)
    result = command_output(adb_command(serial, "exec-out", "cat", remote_path))
    xml_text = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    stripped = xml_text.lstrip()
    if not stripped.startswith("<?xml") and not stripped.startswith("<hierarchy"):
        raise SystemExit("Failed to fetch a valid UI hierarchy dump from the device.")
    return xml_text


def wait_for_boot(serial: str, timeout_seconds: float) -> None:
    command_output(adb_command(serial, "wait-for-device"), timeout=timeout_seconds)
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        boot_completed = command_output(
            adb_command(serial, "shell", "getprop", "sys.boot_completed"),
            check=False,
        )
        bootanim_state = command_output(
            adb_command(serial, "shell", "getprop", "init.svc.bootanim"),
            check=False,
        )
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
        command_output(
            adb_command(serial, "shell", "settings", "put", "global", setting, "0"),
            check=False,
        )


def tail_text(path: Path, max_lines: int = 20) -> str:
    if not path.exists():
        return ""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    return "\n".join(lines[-max_lines:])


def launch_emulator_process(command: Sequence[str], log_path: Path) -> subprocess.Popen[bytes]:
    env = dict(os.environ)
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


def resolve_runtime_helper_script() -> Path:
    helper_path = Path(__file__).resolve().parents[2] / "android-emulator-deploy-run" / "scripts" / "android_emulator_runtime.py"
    if not helper_path.exists():
        raise SystemExit(f"Runtime helper script not found: {helper_path}")
    return helper_path


def add_runtime_storage_arguments(command: list[str], args: argparse.Namespace) -> None:
    if getattr(args, "avd_home", None):
        command.extend(["--avd-home", args.avd_home])
    if getattr(args, "emulator_home", None):
        command.extend(["--emulator-home", args.emulator_home])
    if getattr(args, "datadir_root", None):
        command.extend(["--datadir-root", args.datadir_root])


def wait_for_matches(serial: str, selector: Selector, wait_seconds: float) -> list[UiNode]:
    deadline = time.time() + wait_seconds
    while True:
        xml_text = fetch_ui_xml(serial)
        matches = filter_nodes(parse_ui_nodes(xml_text), selector)
        if matches:
            return matches
        if time.time() >= deadline:
            return []
        time.sleep(POLL_INTERVAL_SECONDS)


def escape_input_text(value: str) -> str:
    escaped: list[str] = []
    for character in value:
        if character == " ":
            escaped.append("%s")
        elif character in r"&<>\"'()[]{}|;$":
            escaped.append(f"\\{character}")
        else:
            escaped.append(character)
    return "".join(escaped)


def command_doctor(args: argparse.Namespace) -> int:
    command = [sys.executable, str(resolve_runtime_helper_script()), "doctor"]
    add_runtime_storage_arguments(command, args)
    result = command_output(command)
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    if output.strip():
        print(output.strip())
    return 0


def command_boot(args: argparse.Namespace) -> int:
    command = [sys.executable, str(resolve_runtime_helper_script()), "boot"]
    add_runtime_storage_arguments(command, args)
    if args.avd:
        command.extend(["--avd", args.avd])
    if args.headless:
        command.append("--headless")
    if args.cold:
        command.append("--cold")
    if args.wipe_data:
        command.append("--wipe-data")
    if args.disable_animations:
        command.append("--disable-animations")
    if args.save_snapshot_on_exit:
        command.append("--save-snapshot-on-exit")
    command.extend(["--launch-timeout", str(args.launch_timeout)])
    command.extend(["--boot-timeout", str(args.boot_timeout)])
    if args.gpu:
        command.extend(["--gpu", args.gpu])

    result = command_output(command)
    output = result.stdout if isinstance(result.stdout, str) else result.stdout.decode("utf-8", errors="replace")
    if output.strip():
        print(output.strip())
    return 0


def command_dump_ui(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    xml_text = fetch_ui_xml(serial)
    if args.out:
        output_path = Path(args.out)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(xml_text, encoding="utf-8")
        print(f"wrote {output_path}")

    nodes = parse_ui_nodes(xml_text)
    visible_nodes = [
        node
        for node in nodes
        if args.include_blank
        or node.text
        or node.content_desc
        or node.resource_id
        or node.clickable
    ]
    for ordinal, node in enumerate(visible_nodes[: args.limit]):
        print(format_node(node, ordinal))
    if len(visible_nodes) > args.limit:
        print(f"... truncated {len(visible_nodes) - args.limit} more nodes")
    return 0


def command_find(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    selector = selector_from_args(args)
    ensure_selector(selector)
    matches = wait_for_matches(serial, selector, args.wait_seconds)
    if not matches:
        raise SystemExit(f"No UI nodes matched selector: {selector.describe()}")
    for ordinal, node in enumerate(matches):
        print(format_node(node, ordinal))
    return 0


def pick_match(matches: list[UiNode], index: int | None) -> UiNode:
    if index is not None:
        try:
            return matches[index]
        except IndexError as exc:
            raise SystemExit(f"Match index {index} is out of range for {len(matches)} result(s).") from exc
    if len(matches) > 1:
        message = [
            f"Selector matched {len(matches)} nodes. Refine the selector or pass --index.",
        ]
        message.extend(format_node(node, ordinal) for ordinal, node in enumerate(matches))
        raise SystemExit("\n".join(message))
    return matches[0]


def command_tap(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    if args.x is not None and args.y is not None:
        x = args.x
        y = args.y
    else:
        selector = selector_from_args(args)
        ensure_selector(selector)
        matches = wait_for_matches(serial, selector, args.wait_seconds)
        if not matches:
            raise SystemExit(f"No UI nodes matched selector: {selector.describe()}")
        chosen = pick_match(matches, args.index)
        x, y = chosen.center
        print(format_node(chosen))

    if args.dry_run:
        print(f"tap center=({x},{y})")
        return 0

    command_output(adb_command(serial, "shell", "input", "tap", str(x), str(y)))
    print(f"tapped ({x},{y})")
    return 0


def command_type(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    escaped_value = escape_input_text(args.value)
    command_output(adb_command(serial, "shell", "input", "text", escaped_value))
    print(f'typed "{args.value}"')
    return 0


def command_keyevent(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    command_output(adb_command(serial, "shell", "input", "keyevent", args.key))
    print(f"sent keyevent {args.key}")
    return 0


def command_swipe(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    command_output(
        adb_command(
            serial,
            "shell",
            "input",
            "swipe",
            str(args.x1),
            str(args.y1),
            str(args.x2),
            str(args.y2),
            str(args.duration_ms),
        )
    )
    print(f"swiped ({args.x1},{args.y1}) -> ({args.x2},{args.y2}) in {args.duration_ms}ms")
    return 0


def command_screenshot(args: argparse.Namespace) -> int:
    serial = resolve_serial(args.serial)
    result = command_output(adb_command(serial, "exec-out", "screencap", "-p"), text=False)
    image_bytes = result.stdout if isinstance(result.stdout, bytes) else result.stdout.encode("utf-8")
    output_path = Path(args.out)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(image_bytes)
    print(f"wrote {output_path}")
    return 0


def add_common_serial_argument(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--serial", help="adb device serial. Defaults to ANDROID_SERIAL or the sole connected device.")


def add_emulator_storage_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--avd-home")
    parser.add_argument("--emulator-home")
    parser.add_argument("--datadir-root")


def add_selector_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--text")
    parser.add_argument("--text-contains")
    parser.add_argument("--resource-id")
    parser.add_argument("--resource-id-contains")
    parser.add_argument("--content-desc")
    parser.add_argument("--content-desc-contains")
    parser.add_argument("--class-name")
    parser.add_argument("--package")
    parser.add_argument("--clickable", action="store_true")
    parser.add_argument("--enabled", action="store_true")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Small adb helper for Android-emulator-driven acceptance rounds."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    doctor_parser = subparsers.add_parser("doctor", help="Show adb/emulator paths, AVDs, and connected devices.")
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

    dump_parser = subparsers.add_parser("dump-ui", help="Dump the UI hierarchy and print a concise summary.")
    add_common_serial_argument(dump_parser)
    dump_parser.add_argument("--out", help="Write the raw XML hierarchy to this path.")
    dump_parser.add_argument("--include-blank", action="store_true", help="Include nodes without text, desc, or resource id.")
    dump_parser.add_argument("--limit", type=int, default=80)
    dump_parser.set_defaults(func=command_dump_ui)

    find_parser = subparsers.add_parser("find", help="Find UI nodes matching a selector.")
    add_common_serial_argument(find_parser)
    add_selector_arguments(find_parser)
    find_parser.add_argument("--wait-seconds", type=float, default=0.0)
    find_parser.set_defaults(func=command_find)

    tap_parser = subparsers.add_parser("tap", help="Tap a UI node by selector or raw coordinates.")
    add_common_serial_argument(tap_parser)
    add_selector_arguments(tap_parser)
    tap_parser.add_argument("--wait-seconds", type=float, default=10.0)
    tap_parser.add_argument("--index", type=int, help="Zero-based index when a selector matches multiple nodes.")
    tap_parser.add_argument("--x", type=int)
    tap_parser.add_argument("--y", type=int)
    tap_parser.add_argument("--dry-run", action="store_true")
    tap_parser.set_defaults(func=command_tap)

    type_parser = subparsers.add_parser("type", help="Send text to the focused field with adb shell input text.")
    add_common_serial_argument(type_parser)
    type_parser.add_argument("--value", required=True)
    type_parser.set_defaults(func=command_type)

    keyevent_parser = subparsers.add_parser("keyevent", help="Send an Android key event.")
    add_common_serial_argument(keyevent_parser)
    keyevent_parser.add_argument("--key", required=True, help="Example: KEYCODE_ENTER")
    keyevent_parser.set_defaults(func=command_keyevent)

    swipe_parser = subparsers.add_parser("swipe", help="Send a swipe gesture.")
    add_common_serial_argument(swipe_parser)
    swipe_parser.add_argument("--x1", type=int, required=True)
    swipe_parser.add_argument("--y1", type=int, required=True)
    swipe_parser.add_argument("--x2", type=int, required=True)
    swipe_parser.add_argument("--y2", type=int, required=True)
    swipe_parser.add_argument("--duration-ms", type=int, default=250)
    swipe_parser.set_defaults(func=command_swipe)

    screenshot_parser = subparsers.add_parser("screenshot", help="Capture a screenshot from the device.")
    add_common_serial_argument(screenshot_parser)
    screenshot_parser.add_argument("--out", required=True)
    screenshot_parser.set_defaults(func=command_screenshot)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
