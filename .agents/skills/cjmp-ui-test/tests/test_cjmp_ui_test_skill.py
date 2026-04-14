from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parents[1]
SCRIPT_DIR = SKILL_DIR / "scripts"
REFERENCE_DIR = SKILL_DIR / "references"

CHECK_SCRIPT = SCRIPT_DIR / "check_ios_destination.sh"
RUN_SCRIPT = SCRIPT_DIR / "run_xcode_ui_test.sh"
EXPORT_SCRIPT = SCRIPT_DIR / "export_xcresult_attachments.sh"


class CjmpUiTestSkillTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.temp_path = Path(self.temp_dir.name)
        self.bin_dir = self.temp_path / "bin"
        self.bin_dir.mkdir()

        self.write_executable(
            "date",
            """#!/usr/bin/env bash
if [[ "${1:-}" == "-u" && "${2:-}" == "+%Y%m%dT%H%M%SZ" ]]; then
  printf '%s\\n' "${FAKE_DATE_OUTPUT:-20260402T031415Z}"
  exit 0
fi
/bin/date "$@"
""",
        )
        self.write_executable(
            "xcodebuild",
            """#!/usr/bin/env bash
if [[ -n "${XCODEBUILD_ARGS_LOG:-}" ]]; then
  printf '%s\\n' "$*" >"${XCODEBUILD_ARGS_LOG}"
fi
printf '%s' "${XCODEBUILD_STDOUT:-}"
exit "${XCODEBUILD_EXIT_CODE:-0}"
""",
        )
        self.write_executable(
            "xcrun",
            """#!/usr/bin/env bash
if [[ -n "${XCRUN_ARGS_LOG:-}" ]]; then
  printf '%s\\n' "$*" >"${XCRUN_ARGS_LOG}"
fi
output_path=""
prev=""
for arg in "$@"; do
  if [[ "$prev" == "--output-path" ]]; then
    output_path="$arg"
  fi
  prev="$arg"
done
if [[ -n "$output_path" ]]; then
  mkdir -p "$output_path"
fi
exit "${XCRUN_EXIT_CODE:-0}"
""",
        )

        self.base_env = os.environ.copy()
        self.base_env["PATH"] = f"{self.bin_dir}:{self.base_env.get('PATH', '')}"
        self.base_env["FAKE_DATE_OUTPUT"] = "20260402T031415Z"

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def write_executable(self, name: str, content: str) -> None:
        path = self.bin_dir / name
        path.write_text(content)
        path.chmod(0o755)

    def run_script(
        self,
        script: Path,
        *args: str,
        extra_env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        env = dict(self.base_env)
        if extra_env:
            env.update(extra_env)
        return subprocess.run(
            ["bash", str(script), *args],
            capture_output=True,
            text=True,
            cwd=SKILL_DIR,
            env=env,
        )

    def test_skill_documents_require_ohos_ui_test_and_xcode_shell(self) -> None:
        skill_text = (SKILL_DIR / "SKILL.md").read_text()
        workflow_text = (REFERENCE_DIR / "workflow.md").read_text()
        pattern_text = (REFERENCE_DIR / "test-case-patterns.md").read_text()

        self.assertIn("Do not skip the `ohos.ui_test` layer.", skill_text)
        self.assertIn("Do not skip the Xcode UI Test shell.", skill_text)
        self.assertIn("## Device selection", workflow_text)
        self.assertIn("## Acceptance checklist", workflow_text)
        self.assertIn("## Pattern: `form-submit-and-transition`", pattern_text)
        self.assertIn("## Pattern: `success-handoff-and-return`", pattern_text)

    def test_check_ios_destination_matches_visible_device(self) -> None:
        xcodebuild_args_log = self.temp_path / "xcodebuild-args.log"
        result = self.run_script(
            CHECK_SCRIPT,
            "--project",
            "/tmp/app.xcodeproj",
            "--scheme",
            "cjmp",
            "--device-id",
            "00008140-000408510A02801C",
            extra_env={
                "XCODEBUILD_STDOUT": """
Available destinations for the "cjmp" scheme:
    { platform:iOS, arch:arm64, id:00008140-000408510A02801C, name:Cen的iPhone }
""",
                "XCODEBUILD_ARGS_LOG": str(xcodebuild_args_log),
            },
        )

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("MATCHED_DEVICE_ID=00008140-000408510A02801C", result.stdout)
        args = xcodebuild_args_log.read_text()
        self.assertIn("-project /tmp/app.xcodeproj", args)
        self.assertIn("-scheme cjmp", args)
        self.assertIn("-showdestinations", args)

    def test_check_ios_destination_fails_when_device_missing(self) -> None:
        result = self.run_script(
            CHECK_SCRIPT,
            "--project",
            "/tmp/app.xcodeproj",
            "--scheme",
            "cjmp",
            "--device-id",
            "missing-device",
            extra_env={
                "XCODEBUILD_STDOUT": """
Available destinations for the "cjmp" scheme:
    { platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
""",
            },
        )

        self.assertEqual(result.returncode, 2)
        self.assertIn(
            "Requested device id not present in xcodebuild destinations: missing-device",
            result.stderr,
        )

    def test_run_xcode_ui_test_dry_run_prints_expected_command(self) -> None:
        result = self.run_script(
            RUN_SCRIPT,
            "--project",
            "/tmp/app.xcodeproj",
            "--scheme",
            "cjmp",
            "--device-id",
            "device-123",
            "--only-testing",
            "cjmpUITests/CjmpUITests/testRunSmokeCheckFromUiTestPage",
            "--result-bundle-dir",
            str(self.temp_path),
            "--result-prefix",
            "smoke-run",
            "--dry-run",
        )

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn(
            f"RESULT_BUNDLE_PATH={self.temp_path}/smoke-run-20260402T031415Z.xcresult",
            result.stdout,
        )
        self.assertIn("xcodebuild test", result.stdout)
        self.assertIn("-destination id=device-123", result.stdout)
        self.assertIn(
            "-only-testing:cjmpUITests/CjmpUITests/testRunSmokeCheckFromUiTestPage",
            result.stdout,
        )

    def test_run_xcode_ui_test_executes_xcodebuild(self) -> None:
        xcodebuild_args_log = self.temp_path / "xcodebuild-run.log"
        result = self.run_script(
            RUN_SCRIPT,
            "--project",
            "/tmp/app.xcodeproj",
            "--scheme",
            "cjmp",
            "--device-id",
            "device-123",
            "--only-testing",
            "cjmpUITests/CjmpUITests/testRunSmokeCheckFromUiTestPage",
            "--result-bundle-dir",
            str(self.temp_path),
            extra_env={"XCODEBUILD_ARGS_LOG": str(xcodebuild_args_log)},
        )

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        args = xcodebuild_args_log.read_text()
        self.assertIn("test", args)
        self.assertIn("-project /tmp/app.xcodeproj", args)
        self.assertIn("-scheme cjmp", args)
        self.assertIn("-destination id=device-123", args)
        self.assertIn(
            f"-resultBundlePath {self.temp_path}/cjmp-ui-test-20260402T031415Z.xcresult",
            args,
        )

    def test_export_xcresult_attachments_executes_xcrun_and_creates_output_dir(self) -> None:
        result_bundle = self.temp_path / "result.xcresult"
        result_bundle.mkdir()
        xcrun_args_log = self.temp_path / "xcrun.log"

        result = self.run_script(
            EXPORT_SCRIPT,
            "--result-bundle",
            str(result_bundle),
            "--output-dir",
            str(self.temp_path),
            "--output-prefix",
            "attachments",
            extra_env={"XCRUN_ARGS_LOG": str(xcrun_args_log)},
        )

        expected_output_dir = self.temp_path / "attachments-20260402T031415Z"
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn(f"ATTACHMENTS_PATH={expected_output_dir}", result.stdout)
        self.assertTrue(expected_output_dir.is_dir())
        args = xcrun_args_log.read_text()
        self.assertIn("xcresulttool export attachments", args)
        self.assertIn(f"--path {result_bundle}", args)
        self.assertIn(f"--output-path {expected_output_dir}", args)


if __name__ == "__main__":
    unittest.main()
