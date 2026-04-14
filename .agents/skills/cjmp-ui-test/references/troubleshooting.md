# Troubleshooting

## Xcode cannot see the real device

Symptom:

- `xcodebuild` says the destination id is unavailable
- `-showdestinations` only shows `My Mac` and placeholder iOS destinations

Checks:

- unlock the phone
- confirm the phone trusts the Mac
- reconnect the cable
- open Xcode `Window > Devices and Simulators`
- rerun `xcodebuild -showdestinations`

Do not keep rerunning the same device id until it appears in `-showdestinations`.

## `-resultBundlePath` already exists

Symptom:

- `xcodebuild: error: Existing file at -resultBundlePath`

Fix:

- use a new timestamped bundle name
- prefer this over deleting unrelated result bundles

The bundled `run_xcode_ui_test.sh` script already generates a fresh path each time.

## The expected `.xcresult` bundle is gone

Symptom:

- `xcresulttool export attachments` says the path does not exist
- an older bundle under `/tmp` was cleaned up already

Fix:

- rerun the XCTest to produce a fresh bundle
- copy the printed `RESULT_BUNDLE_PATH` immediately if you need to reuse it later
- prefer exporting attachments right after the test run

## Semantic XCTest lookup does not expose buttons

Symptom:

- accessibility hierarchy shows mostly `Other`
- `app.buttons["Run smoke check"]` or similar lookups do not work reliably

Fix:

- keep the in-app smoke harness
- use normalized coordinate taps from the window instead of semantic taps
- attach screenshots before and after the smoke trigger

## The final screenshot proves the wrong button was tapped

Typical signs:

- app returns to login instead of staying on the smoke page
- status text remains `Ready to run...`
- the screenshot shows the smoke button untouched

Fix:

- inspect the screenshot
- compute a new normalized coordinate from the visible button center
- change only the affected coordinate
- rerun the same narrow XCTest

## XCTest passes but the embedded smoke did not run

Symptom:

- the outer XCTest finishes successfully
- final screenshot does not show `Smoke suite passed` or another terminal status

Fix:

- treat this as a test failure in practice
- inspect the app-side status text and logs
- verify that the second tap hit `Run smoke check`
- verify the embedded `ohos.ui_test` suite contains real assertions

## `devicectl diagnose` warnings after success

Symptom:

- `xcodebuild` shows a diagnostic collection warning near the end
- the test itself still says `** TEST SUCCEEDED **`

Interpretation:

- this is usually a post-test diagnostic collection problem
- if the XCTest and screenshot evidence are correct, treat the UI test run as successful

## Attachment export tips

- export attachments from the `.xcresult` bundle
- inspect both the `after-open-ui-test-page` screenshot and the final result screenshot
- use the first screenshot to retarget taps and the final screenshot to verify outcome
