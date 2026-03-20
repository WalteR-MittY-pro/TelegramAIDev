from __future__ import annotations

import argparse
import sys
import unittest
from unittest import mock
from pathlib import Path

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
        self.assertEqual(devices[1].state, "unauthorized")

    def test_apk_metadata_from_badging(self) -> None:
        metadata = android_emulator_runtime.apk_metadata_from_badging(SAMPLE_BADGING)
        self.assertEqual(metadata.package_name, "org.example.app")
        self.assertEqual(metadata.launchable_activity, "org.example.app.MainActivity")

    def test_parse_resolve_activity(self) -> None:
        self.assertEqual(
            android_emulator_runtime.parse_resolve_activity(SAMPLE_RESOLVE_ACTIVITY),
            "org.example.app/.MainActivity",
        )

    def test_normalize_component(self) -> None:
        self.assertEqual(
            android_emulator_runtime.normalize_component("org.example.app", ".MainActivity"),
            "org.example.app/.MainActivity",
        )
        self.assertEqual(
            android_emulator_runtime.normalize_component("org.example.app", "org.example.app.MainActivity"),
            "org.example.app/org.example.app.MainActivity",
        )

    def test_parse_am_start_error(self) -> None:
        self.assertIsNone(android_emulator_runtime.parse_am_start_error(SAMPLE_AM_START_SUCCESS))
        self.assertEqual(
            android_emulator_runtime.parse_am_start_error(SAMPLE_AM_START_FAILURE),
            "Error type 3\nError: Activity class {org.example.app/org.example.app.MissingActivity} does not exist.",
        )

    def test_parse_monkey_error(self) -> None:
        self.assertEqual(
            android_emulator_runtime.parse_monkey_error(SAMPLE_MONKEY_FAILURE),
            "** No activities found to run, monkey aborted.",
        )

    @mock.patch.object(android_emulator_runtime, "WORKSPACE_DATADIR_ROOT", Path("/tmp/workspace-data"))
    @mock.patch.object(android_emulator_runtime, "WORKSPACE_EMULATOR_HOME", Path("/tmp/workspace-home"))
    @mock.patch.object(android_emulator_runtime, "WORKSPACE_AVD_HOME", Path("/tmp/workspace-home/avd"))
    @mock.patch.object(android_emulator_runtime, "avd_home_has_definitions", return_value=True)
    def test_resolve_emulator_storage_prefers_workspace_avd_home(
        self,
        _has_definitions: mock.Mock,
    ) -> None:
        with mock.patch.dict(android_emulator_runtime.os.environ, {}, clear=True):
            storage = android_emulator_runtime.resolve_emulator_storage()
        self.assertEqual(storage.source, "workspace")
        self.assertEqual(storage.avd_home, Path("/tmp/workspace-home/avd"))
        self.assertEqual(storage.emulator_home, Path("/tmp/workspace-home"))
        self.assertEqual(storage.datadir_root, Path("/tmp/workspace-data"))
        self.assertEqual(storage.env["ANDROID_AVD_HOME"], "/tmp/workspace-home/avd")
        self.assertEqual(storage.env["ANDROID_EMULATOR_HOME"], "/tmp/workspace-home")

    @mock.patch.object(android_emulator_runtime, "disable_animations")
    @mock.patch.object(android_emulator_runtime, "wait_for_boot")
    @mock.patch.object(android_emulator_runtime, "wait_for_new_emulator")
    @mock.patch.object(android_emulator_runtime, "launch_emulator_process")
    @mock.patch.object(android_emulator_runtime.Path, "mkdir")
    @mock.patch.object(android_emulator_runtime.time, "sleep")
    @mock.patch.object(android_emulator_runtime, "list_devices", return_value=[])
    @mock.patch.object(
        android_emulator_runtime,
        "resolve_emulator_storage",
        return_value=android_emulator_runtime.EmulatorStorage(
            env={"ANDROID_AVD_HOME": "/tmp/avd", "ANDROID_EMULATOR_HOME": "/tmp/home"},
            source="workspace",
            emulator_home=Path("/tmp/home"),
            avd_home=Path("/tmp/avd"),
            datadir_root=Path("/tmp/data"),
        ),
    )
    @mock.patch.object(android_emulator_runtime, "resolve_emulator", return_value="/tmp/emulator")
    @mock.patch.object(android_emulator_runtime, "list_avds", return_value=["Pixel_3a_API_34"])
    def test_command_boot_retries_after_early_exit(
        self,
        _list_avds: mock.Mock,
        _resolve_emulator: mock.Mock,
        _resolve_emulator_storage: mock.Mock,
        _list_devices: mock.Mock,
        sleep: mock.Mock,
        _mkdir: mock.Mock,
        launch_emulator_process: mock.Mock,
        wait_for_new_emulator: mock.Mock,
        wait_for_boot: mock.Mock,
        disable_animations: mock.Mock,
    ) -> None:
        process = mock.Mock()
        process.poll.return_value = 1
        launch_emulator_process.return_value = process
        wait_for_new_emulator.side_effect = [SystemExit("failed first launch"), "emulator-5554"]

        args = argparse.Namespace(
            avd="Pixel_3a_API_34",
            headless=True,
            cold=False,
            wipe_data=False,
            disable_animations=True,
            save_snapshot_on_exit=False,
            launch_timeout=1.0,
            boot_timeout=1.0,
            gpu="swiftshader_indirect",
            avd_home=None,
            emulator_home=None,
            datadir_root=None,
        )

        self.assertEqual(android_emulator_runtime.command_boot(args), 0)
        self.assertEqual(launch_emulator_process.call_count, 2)
        first_command = launch_emulator_process.call_args_list[0].args[0]
        second_command = launch_emulator_process.call_args_list[1].args[0]
        first_env = launch_emulator_process.call_args_list[0].args[2]
        self.assertNotIn("-no-snapshot-load", first_command)
        self.assertIn("-no-snapshot-load", second_command)
        self.assertIn("-datadir", first_command)
        self.assertIn("/tmp/data/Pixel_3a_API_34", first_command)
        self.assertEqual(first_env["ANDROID_AVD_HOME"], "/tmp/avd")
        wait_for_boot.assert_called_once_with("emulator-5554", 1.0)
        disable_animations.assert_called_once_with("emulator-5554")
        sleep.assert_called_once_with(android_emulator_runtime.EMULATOR_LAUNCH_RETRY_DELAY_SECONDS)


if __name__ == "__main__":
    unittest.main()
