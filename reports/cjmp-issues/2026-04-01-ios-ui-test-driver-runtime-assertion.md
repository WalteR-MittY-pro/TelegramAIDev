# iOS app-process `ohos.ui_test` assertions fail with `BusinessException 17000003`

## Issue summary

Calling `ohos.ui_test.Driver.create()` and `driver.assertComponentExist(...)` directly from the app UI flow compiles successfully, but tapping the in-app smoke-check button on iOS/iOS simulator fails at runtime with `BusinessException`, `errorcode 17000003`, `message Assertion failed`.

## Reproduction or context

1. Open the UI test page in `/Users/dzy/Desktop/project/TelegramAIDev/apps/cjmp/lib/index.cj`.
2. Tap `Run smoke check`.
3. The previous implementation called `UITestSmokeCase.loginPhoneEntryCase()` from `/Users/dzy/Desktop/project/TelegramAIDev/apps/cjmp/lib/ui_test_smoke_case.cj`.
4. That smoke case created a `Driver` and immediately executed `assertComponentExist(On().id(...))`.
5. Runtime failed with `BusinessException 17000003` instead of returning a recoverable result to the page.

## Impact on AI-assisted delivery

- The API surface is available in normal app sources and links into the iOS target, so an agent can reasonably infer that a small in-app smoke check is supported.
- The actual runtime contract is narrower: driver-backed UI assertions appear to require an external automation harness, not the app process itself.
- Because that contract is not enforced earlier or surfaced with a clearer diagnostic, the round spent time reproducing and re-partitioning the smoke check into:
  - a safe embedded selector-contract check inside the app
  - the original `UITestSmokeCase` for external automation only

## Related slice

- `CJMP` Telegram commercial MVP
- UI test smoke page on the slice2 demo login shell

## Workaround used in this repo

- Stop calling `UITestSmokeCase.loginPhoneEntryCase()` from the app UI page.
- Keep selector IDs shared in `/Users/dzy/Desktop/project/TelegramAIDev/apps/cjmp/lib/ui_test_selectors.cj`.
- Run the page button as an embedded selector-contract check only.
- Reserve `ohos.ui_test.Driver` assertions for external automation entry points.

## Upstream issue link

- not created yet
