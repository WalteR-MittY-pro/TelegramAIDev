# Workflow

## Decision Rule

When this skill triggers for CJMP iOS UI automation, do not debate whether to use the testing stack.
Assume the correct stack is:

- app-side smoke-entry UI
- `ohos.ui_test` case skeleton
- Xcode UI Test shell

Only skip one of these if the user explicitly requests a different strategy.

If AI-generated CJMP UI code already exists but the test framework wiring does not, add the missing wiring as part of the task.

## Inputs to collect

If `ohos.ui_test` API behavior or platform notes are unclear, consult [cjmp-test-framework.md](cjmp-test-framework.md) before guessing.

Collect these inputs before execution:

- Xcode project path, for example `apps/cjmp/ios/cjmp.xcodeproj`
- shared scheme name, for example `cjmp`
- target XCTest name, for example `cjmpUITests/CjmpUITests/testRunSmokeCheckFromUiTestPage`
- bundle id when manual launch is needed, for example `com.example.cjmp`
- visible real-device ids from `xcodebuild -showdestinations`

## Required stack

### 1. App-side smoke-entry UI

Prefer a stable in-app smoke entry instead of trying to drive every production screen directly from XCTest.

Recommended pieces:

- a route constant for the smoke page, such as `ROUTE_UI_TEST`
- a button that opens the smoke page from a predictable entry screen
- a `Run smoke check` button on the smoke page
- a status text field on the smoke page that reports `running`, `passed`, `failed`, or `crashed`
- stable selector ids for every element the `ohos.ui_test` suite touches

When the user asks to validate a new UI slice, prefer extending this harness instead of inventing a separate one-off path.

### 2. `ohos.ui_test` case skeleton

Put the real assertions in the CJMP smoke suite.

Use the same structural pattern the framework documentation shows:

```cangjie
import std.unittest.*
import std.unittest.testmacro.*
import ohos.ui_test.*

@Test
public class UITestSmokeSuite {
    @TestCase
    func test_target_flow() {
        let driver = Driver.create()
        try {
            driver.assertComponentExist(On().id("target_id"))
            let component = driver.findComponent(On().id("target_id"))
            @Expect(component.isClickable(), true)
            assert(true)
        } catch (e: BusinessException) {
            @Expect(false)
        }
    }
}
```

Typical checks:

- `driver.assertComponentExist(On().id(...))`
- `@Expect(component.getText(), "Expected copy")`
- `@Expect(button.isClickable(), true)`
- `assert(condition)`

Choose assertions that prove the end-to-end flow succeeded:

- target page exists
- expected text or state is visible
- reopening the smoke page still shows the expected control
- the final page matches the expected route or handoff state

### 3. Xcode UI Test shell

Keep the Swift/XCTest layer small, but always include it for real-device automation.

Typical wrapper shape:

```swift
let app = XCUIApplication()
app.launchArguments = [
    "test", "bundleName", "bundleName",
    "moduleName", "moduleName",
    "unittest", "unittest",
    "timeout", "101",
]
app.launch()

let window = app.windows.element(boundBy: 0)
XCTAssertTrue(window.waitForExistence(timeout: 10))

window.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.80)).tap()
window.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.91)).tap()
```

Wrapper responsibilities:

1. launch the app with AbilityDelegator arguments
2. wait for the main window
3. open the smoke page
4. attach a screenshot after opening the smoke page
5. tap the in-app `Run smoke check` trigger
6. wait long enough for the embedded suite to finish
7. attach the final screenshot

If semantic lookup works, prefer that.
If accessibility only exposes generic `Other` nodes, use normalized window coordinates.

Normalized coordinate formula:

- `dx = target_x / screenshot_pixel_width`
- `dy = target_y / screenshot_pixel_height`

Retarget only the missed coordinate. Keep the rest of the driver unchanged.

## Device selection

Prefer a connected real iPhone.

Selection rules:

1. Run `scripts/check_ios_destination.sh` or `xcodebuild -showdestinations`.
2. If exactly one real iPhone is visible and unlocked, use it.
3. If multiple real iPhones are visible, prefer the one the user named; otherwise ask before continuing.
4. If only placeholder iOS destinations appear, the device is not ready. Fix the connection before testing.

Treat these as blockers:

- locked phone
- untrusted Mac pairing
- cable disconnected
- device id not present in `-showdestinations`

## Launch sequence

Check whether Xcode can see the device:

```bash
scripts/check_ios_destination.sh \
  --project /abs/path/to/cjmp.xcodeproj \
  --scheme cjmp \
  --device-id <device-id>
```

Run the narrow XCTest with a fresh result bundle:

```bash
scripts/run_xcode_ui_test.sh \
  --project /abs/path/to/cjmp.xcodeproj \
  --scheme cjmp \
  --device-id <device-id> \
  --only-testing cjmpUITests/CjmpUITests/testRunSmokeCheckFromUiTestPage
```

Export screenshots:

```bash
scripts/export_xcresult_attachments.sh \
  --result-bundle /tmp/cjmp-ui-test-<timestamp>.xcresult
```

Optional manual launch when you need app logs outside XCTest:

```bash
xcrun devicectl device process launch \
  --device <device-id> \
  --terminate-existing \
  --console \
  <bundle-id> \
  test bundleName bundleName moduleName moduleName unittest unittest timeout 101
```

Use manual launch for debugging or log capture.
Use `xcodebuild test` for automated tapping.

## Acceptance checklist

Do not stop at `** TEST SUCCEEDED **`.

Accept the change only if all of these are true:

- the app actually reached the smoke page
- the `Run smoke check` tap hit the intended button
- the final screenshot shows the smoke page or other expected terminal page
- the status text explicitly reports `Smoke suite passed`, `Smoke suite failed`, or `Smoke suite crashed`
- the evidence shows the embedded `ohos.ui_test` assertions actually ran
- the final state matches the user-facing behavior the UI slice was supposed to deliver

If any one of these is missing, treat the result as incomplete and keep iterating.

## Reporting

Summarize:

- which UI slice was covered
- which `ohos.ui_test` case was added or updated
- which XCTest wrapper was used
- which device id was targeted
- how the device was selected
- whether the final screenshot proved the embedded suite passed
- whether any coordinate retargeting was needed
- any remaining instability, such as device visibility or semantic lookup limits
