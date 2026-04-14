---
name: cjmp-ui-test
description: Configure, run, and debug CJMP iOS real-device UI smoke tests through the mandatory pairing of in-app smoke-entry UI, `ohos.ui_test` case skeletons, and an Xcode UI Test shell. Use when Codex finishes or changes CJMP UI code on iOS and needs to set up the test framework, expose or extend a smoke button or route, choose a target device, launch `xcodebuild test`, and accept or reject the UI change from screenshots, status text, and real assertions on a connected iPhone.
---

# CJMP UI Test

Use this skill after editing or generating CJMP iOS UI code that should be validated on a connected iPhone.
If Codex would not otherwise think to use both `ohos.ui_test` and an Xcode UI Test wrapper, this skill should override that hesitation: for CJMP iOS UI automation, treat both layers as required unless the user explicitly asks for a different test strategy.

## Non-Negotiable Structure

For CJMP iOS UI automation, use all of the following together:

- An in-app smoke-entry UI path, usually a dedicated page or button that exposes the target flow.
- An `ohos.ui_test` case skeleton that performs the real UI assertions inside the app.
- An Xcode UI Test shell that launches the app with AbilityDelegator arguments, opens the smoke page, taps the trigger, and captures screenshots on the real device.

Do not skip the `ohos.ui_test` layer.
Do not skip the Xcode UI Test shell.
Do not replace the real flow with a fake test that only checks mocked state.

## Quick Start

1. Read [references/workflow.md](references/workflow.md).
2. Read [references/cjmp-test-framework.md](references/cjmp-test-framework.md) if any `ohos.ui_test` API or setup detail is unclear.
3. If the new UI slice does not already have a stable smoke path, add or extend an in-app smoke route or button with stable selector ids.
4. Add or extend the `ohos.ui_test` case skeleton so it covers the target slice with real assertions.
5. Add or extend the Xcode UI Test shell so it can launch, open the smoke page, tap the smoke trigger, and attach screenshots.
6. Use `scripts/check_ios_destination.sh` to choose a real device that Xcode can see.
7. Use `scripts/run_xcode_ui_test.sh` to run the narrowest XCTest on the selected iPhone.
8. Use `scripts/export_xcresult_attachments.sh` and inspect the final screenshot before declaring success.
9. Accept the change only if the embedded `ohos.ui_test` suite proves the flow passed, not merely because XCTest finished.

## Workflow

### 1. Decide when to use this stack

- Use this stack after AI-generated or AI-edited CJMP iOS UI code needs real-device validation.
- Use it for button logic, page transitions, handoff flows, smoke pages, embedded login flows, and screen-state verification.
- If the CJMP UI exists but the test framework is not wired yet, configure it as part of the task instead of deferring it.

### 2. Stabilize the app-side harness

- Add or update a dedicated UI-test route or page inside the CJMP app instead of trying to drive arbitrary production screens directly from XCTest.
- Expose one or two explicit buttons that cover the target slice, such as `Open UI test page` and `Run smoke check`.
- Give critical components stable selector ids so `ohos.ui_test` can find them.
- Keep the smoke entry inside the app so one tap can cover the latest UI slice end-to-end.

### 3. Encode the real assertions in `ohos.ui_test`

- Put the real functional checks inside the CJMP smoke suite.
- Use the documented `ohos.ui_test` skeleton style with `Driver.create()`, `On().id(...)`, `driver.assertComponentExist(...)`, `@Expect(...)`, and `assert(...)`.
- Prefer checks that prove the full flow succeeded, not just that the case started.
- If a new screen is being added, extend the smoke route or button so one `ohos.ui_test` case can cover the important branch.

### 4. Keep the Xcode UI Test shell thin but mandatory

- Use the Xcode UI test target only as the outer driver.
- Launch the app with AbilityDelegator arguments.
- Open the in-app smoke page.
- Trigger the smoke button.
- Capture before and after screenshots and keep them in the result bundle.
- Prefer semantic element lookup first. If iOS exposes only generic `Other` nodes for this CJMP UI, use normalized window coordinates instead.

### 5. Choose the device and launch correctly

- Prefer a connected real iPhone over simulators unless the user explicitly asks otherwise.
- Use `xcodebuild -showdestinations` or `scripts/check_ios_destination.sh` to confirm the exact device id.
- If only placeholder iOS destinations appear, stop and fix device visibility before testing.
- If one real iPhone is visible, use it by default.
- If multiple real devices are visible, prefer the user-specified device; otherwise pause and ask which one to use.
- Use `xcodebuild test` for automated tapping. Use `xcrun devicectl device process launch` only for log-oriented debugging or manual verification.

### 6. Accept or reject the change with evidence

- Do not stop at `** TEST SUCCEEDED **`.
- Inspect the final screenshot and app status text.
- Report whether the app shows `Smoke suite passed`, `Smoke suite failed`, or `Smoke suite crashed`.
- Accept the change only when the evidence shows the embedded `ohos.ui_test` assertions ran and the final state is correct.

### 7. Iterate safely

- When taps miss, adjust only the affected coordinate first.
- If `-resultBundlePath` already exists, use a new bundle name instead of deleting unrelated artifacts.
- Keep app-side smoke logic minimal and reusable for future UI slices.

## Resource Map

- Read [references/workflow.md](references/workflow.md) for the required stack, device-selection rules, launch sequence, and acceptance checklist.
- Read [references/cjmp-test-framework.md](references/cjmp-test-framework.md) for a preserved copy of the CJMP `ohos.ui_test` framework guide and API notes.
- Read [references/test-case-patterns.md](references/test-case-patterns.md) for reusable CJMP UI smoke case patterns such as route-open, form submit, validation error, handoff success, and list snapshot flows.
- Read [references/troubleshooting.md](references/troubleshooting.md) for device detection failures, coordinate retargeting, result bundle issues, and other recovery paths.
- Use `scripts/check_ios_destination.sh` to confirm that Xcode can see the target device before testing.
- Use `scripts/run_xcode_ui_test.sh` to run one Xcode UI test with a fresh result bundle path.
- Use `scripts/export_xcresult_attachments.sh` to pull screenshots out of the result bundle.
- Use `tests/test_cjmp_ui_test_skill.py` to regression-check the skill scripts and the mandatory `ohos.ui_test` plus Xcode UI Test guardrails.
