from __future__ import annotations

import argparse
import io
import json
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import android_emulator_runtime


SAMPLE_DEVICES = """List of devices attached
emulator-5554          device product:sdk_gphone64_arm64 model:sdk_gphone64_arm64 device:emu64a transport_id:1
ZY22B7                unauthorized usb:336592896X product:foo model:bar device:baz transport_id:2
"""

SAMPLE_BADGING = """package: name='org.example.app' versionCode='1' versionName='1.0'
launchable-activity: name='org.example.app.MainActivity'  label='' icon=''
"""

SAMPLE_RESOLVE_ACTIVITY = """priority=0 preferredOrder=0 match=0x108000 specificIndex=-1 isDefault=true
org.example.app/.MainActivity
"""

SAMPLE_AM_START_SUCCESS = """Starting: Intent { cmp=org.example.app/.MainActivity }
Status: ok
LaunchState: COLD
Activity: org.example.app/.MainActivity
TotalTime: 210
Complete
"""

SAMPLE_AM_START_FAILURE = """Starting: Intent { cmp=org.example.app/.MissingActivity }
Error type 3
Error: Activity class {org.example.app/org.example.app.MissingActivity} does not exist.
"""

SAMPLE_MONKEY_FAILURE = """Events injected: 1
** No activities found to run, monkey aborted.
"""


class AndroidEmulatorRuntimeTests(unittest.TestCase):
    def test_parse_devices(self) -> None:
        devices = android_emulator_runtime.parse_devices(SAMPLE_DEVICES)
        self.assertEqual(len(devices), 2)
        self.assertTrue(devices[0].is_emulator)

    def test_apk_metadata_from_badging(self) -> None:
        metadata = android_emulator_runtime.apk_metadata_from_badging(SAMPLE_BADGING)
        self.assertEqual(metadata.package_name, "org.example.app")
        self.assertEqual(metadata.launchable_activity, "org.example.app.MainActivity")

    def test_parse_am_start_error(self) -> None:
        self.assertIsNone(android_emulator_runtime.parse_am_start_error(SAMPLE_AM_START_SUCCESS))
        self.assertIn("does not exist", android_emulator_runtime.parse_am_start_error(SAMPLE_AM_START_FAILURE) or "")

    def test_parse_monkey_error(self) -> None:
        self.assertIn("monkey aborted", android_emulator_runtime.parse_monkey_error(SAMPLE_MONKEY_FAILURE) or "")

    @mock.patch.object(android_emulator_runtime, "WORKSPACE_LOG_DIR", Path("/tmp/workspace-logs"))
    @mock.patch.object(android_emulator_runtime, "WORKSPACE_DATADIR_ROOT", Path("/tmp/workspace-data"))
    @mock.patch.object(android_emulator_runtime, "WORKSPACE_EMULATOR_HOME", Path("/tmp/workspace-home"))
    @mock.patch.object(android_emulator_runtime, "WORKSPACE_AVD_HOME", Path("/tmp/workspace-home/avd"))
    @mock.patch.object(android_emulator_runtime, "avd_home_has_definitions", return_value=True)
    def test_resolve_runtime_layout_prefers_workspace_defaults(self, _has_definitions: mock.Mock) -> None:
        with mock.patch.dict(android_emulator_runtime.os.environ, {}, clear=True):
            layout = android_emulator_runtime.resolve_runtime_layout()
        self.assertEqual(layout.source, "workspace")
        self.assertEqual(layout.avd_home, Path("/tmp/workspace-home/avd"))
        self.assertEqual(layout.log_dir, Path("/tmp/workspace-logs"))

    @mock.patch.object(android_emulator_runtime, "resolve_serial", return_value="emulator-5554")
    @mock.patch.object(android_emulator_runtime, "perform_install", return_value=(android_emulator_runtime.ApkMetadata("org.example.app", ".MainActivity"), "Success"))
    @mock.patch.object(android_emulator_runtime, "perform_run", return_value="started org.example.app/.MainActivity")
    def test_command_deploy_installs_and_runs(self, perform_run: mock.Mock, perform_install: mock.Mock, _resolve_serial: mock.Mock) -> None:
        args = argparse.Namespace(
            serial=None,
            apk="/tmp/app.apk",
            grant_all_permissions=False,
            allow_test_apks=False,
            allow_downgrade=False,
            package=None,
            activity=None,
            stop_before_start=False,
            no_wait=False,
            no_run=False,
        )
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(android_emulator_runtime.command_deploy(args), 0)
        perform_install.assert_called_once()
        perform_run.assert_called_once()
        self.assertIn("installed /tmp/app.apk", output.getvalue())

    @mock.patch.object(android_emulator_runtime, "list_devices", return_value=[android_emulator_runtime.Device("emulator-5554", "device", {"model": "sdk_phone"})])
    @mock.patch.object(android_emulator_runtime, "running_emulator_name", return_value="Pixel_3a_API_34")
    def test_command_devices_json(self, _running_name: mock.Mock, _list_devices: mock.Mock) -> None:
        args = argparse.Namespace(json=True)
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(android_emulator_runtime.command_devices(args), 0)
        payload = json.loads(output.getvalue())
        self.assertEqual(payload["devices"][0]["avd_name"], "Pixel_3a_API_34")

    @mock.patch.object(android_emulator_runtime, "resolve_serial", return_value="emulator-5554")
    @mock.patch.object(android_emulator_runtime, "perform_uninstall", return_value="Success")
    def test_command_uninstall(self, perform_uninstall: mock.Mock, _resolve_serial: mock.Mock) -> None:
        args = argparse.Namespace(serial=None, package="org.example.app")
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(android_emulator_runtime.command_uninstall(args), 0)
        perform_uninstall.assert_called_once_with("emulator-5554", "org.example.app")

    def test_parser_keeps_aliases(self) -> None:
        parser = android_emulator_runtime.build_parser()
        install_args = parser.parse_args(["install-apk", "--apk", "/tmp/app.apk"])
        run_args = parser.parse_args(["start-app", "--package", "org.example.app"])
        self.assertEqual(install_args.func, android_emulator_runtime.command_install)
        self.assertEqual(run_args.func, android_emulator_runtime.command_run)


if __name__ == "__main__":
    unittest.main()
