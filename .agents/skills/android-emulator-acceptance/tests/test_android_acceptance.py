from __future__ import annotations

import argparse
import sys
import unittest
from unittest import mock
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import android_acceptance


SAMPLE_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<hierarchy rotation="0">
  <node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="org.example" content-desc="" clickable="false" enabled="true" bounds="[0,0][1080,2400]">
    <node index="0" text="Continue" resource-id="org.example:id/continue" class="android.widget.Button" package="org.example" content-desc="Continue button" clickable="true" enabled="true" bounds="[100,1800][980,1950]" />
    <node index="1" text="Phone number" resource-id="org.example:id/phone" class="android.widget.EditText" package="org.example" content-desc="" clickable="true" enabled="true" bounds="[80,900][1000,1050]" />
    <node index="2" text="Secondary Continue" resource-id="org.example:id/secondary_continue" class="android.widget.Button" package="org.example" content-desc="" clickable="true" enabled="true" bounds="[100,1980][980,2120]" />
  </node>
</hierarchy>
"""


class AndroidAcceptanceTests(unittest.TestCase):
    def test_parse_bounds(self) -> None:
        self.assertEqual(android_acceptance.parse_bounds("[10,20][30,40]"), (10, 20, 30, 40))

    def test_parse_ui_nodes(self) -> None:
        nodes = android_acceptance.parse_ui_nodes(SAMPLE_XML)
        self.assertEqual(len(nodes), 4)
        self.assertEqual(nodes[1].text, "Continue")
        self.assertEqual(nodes[1].center, (540, 1875))

    def test_filter_nodes_by_exact_text(self) -> None:
        nodes = android_acceptance.parse_ui_nodes(SAMPLE_XML)
        selector = android_acceptance.Selector(text="Continue")
        matches = android_acceptance.filter_nodes(nodes, selector)
        self.assertEqual(len(matches), 1)
        self.assertEqual(matches[0].resource_id, "org.example:id/continue")

    def test_filter_nodes_by_contains_and_clickable(self) -> None:
        nodes = android_acceptance.parse_ui_nodes(SAMPLE_XML)
        selector = android_acceptance.Selector(text_contains="Continue", clickable=True)
        matches = android_acceptance.filter_nodes(nodes, selector)
        self.assertEqual([node.text for node in matches], ["Continue", "Secondary Continue"])

    def test_escape_input_text(self) -> None:
        self.assertEqual(
            android_acceptance.escape_input_text("demo phone & more"),
            "demo%sphone%s\\&%smore",
        )

    @mock.patch.object(android_acceptance, "command_output")
    @mock.patch.object(android_acceptance, "resolve_runtime_helper_script", return_value=Path("/tmp/android_emulator_runtime.py"))
    def test_command_boot_delegates_to_runtime_helper(
        self,
        resolve_runtime_helper_script: mock.Mock,
        command_output: mock.Mock,
    ) -> None:
        command_output.return_value = mock.Mock(stdout="emulator-5554\n")
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
            avd_home="/tmp/avd",
            emulator_home="/tmp/home",
            datadir_root="/tmp/data",
        )

        self.assertEqual(android_acceptance.command_boot(args), 0)
        resolve_runtime_helper_script.assert_called_once_with()
        command_output.assert_called_once_with(
            [
                sys.executable,
                "/tmp/android_emulator_runtime.py",
                "boot",
                "--avd-home",
                "/tmp/avd",
                "--emulator-home",
                "/tmp/home",
                "--datadir-root",
                "/tmp/data",
                "--avd",
                "Pixel_3a_API_34",
                "--headless",
                "--disable-animations",
                "--launch-timeout",
                "1.0",
                "--boot-timeout",
                "1.0",
                "--gpu",
                "swiftshader_indirect",
            ]
        )

    @mock.patch.object(android_acceptance, "command_output")
    @mock.patch.object(android_acceptance, "resolve_runtime_helper_script", return_value=Path("/tmp/android_emulator_runtime.py"))
    def test_command_doctor_delegates_to_runtime_helper(
        self,
        resolve_runtime_helper_script: mock.Mock,
        command_output: mock.Mock,
    ) -> None:
        command_output.return_value = mock.Mock(stdout="doctor output\n")
        args = argparse.Namespace(
            avd_home="/tmp/avd",
            emulator_home=None,
            datadir_root="/tmp/data",
        )
        self.assertEqual(android_acceptance.command_doctor(args), 0)
        resolve_runtime_helper_script.assert_called_once_with()
        command_output.assert_called_once_with(
            [
                sys.executable,
                "/tmp/android_emulator_runtime.py",
                "doctor",
                "--avd-home",
                "/tmp/avd",
                "--datadir-root",
                "/tmp/data",
            ]
        )


if __name__ == "__main__":
    unittest.main()
