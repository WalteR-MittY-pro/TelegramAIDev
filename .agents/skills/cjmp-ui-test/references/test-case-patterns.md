# Test Case Patterns

Use these patterns as the default starting point when adding or extending CJMP iOS smoke coverage.
Prefer adapting the nearest pattern instead of inventing a brand-new structure.

## Pattern Selection

- Use `route-open-visible-state` when the new UI slice adds a page, panel, or route that should become visible after one action.
- Use `form-submit-and-transition` when the flow requires input, a primary CTA, and a route or state transition.
- Use `validation-error-state` when the flow should reject empty or invalid input and show an error message.
- Use `success-handoff-and-return` when the flow should land on a success state, then reopen or re-enter the smoke page.
- Use `scroll-search-or-snapshot` when the UI slice depends on long content, list traversal, or component screenshots.

## Shared Helpers

Use a helper like this when multiple cases need transition waits:

```cangjie
private func requireComponentAfterTransition(driver: Driver, componentId: String, transitionDelayMs: Int32): UIComponent {
    driver.delayMs(transitionDelayMs)
    driver.assertComponentExist(On().id(componentId))
    driver.findComponent(On().id(componentId))
}
```

Keep helpers short and deterministic.

## Pattern: `route-open-visible-state`

Use when a button or route should reveal a new page and expose stable copy.

```cangjie
@TestCase
func test_open_target_page() {
    let driver = Driver.create()
    try {
        driver.assertComponentExist(On().id(OPEN_TARGET_PAGE_ID))
        let openButton = driver.findComponent(On().id(OPEN_TARGET_PAGE_ID))
        @Expect(openButton.isClickable(), true)
        openButton.click()

        let pageTitle = requireComponentAfterTransition(driver, TARGET_PAGE_TITLE_ID, 300)
        @Expect(pageTitle.getText(), "Expected target title")
    } catch (e: BusinessException) {
        @Expect(false)
    }
}
```

## Pattern: `form-submit-and-transition`

Use when the flow requires text entry, a primary button, and a success transition.

```cangjie
@TestCase
func test_submit_form_and_open_next_step() {
    let driver = Driver.create()
    try {
        let input = driver.findComponent(On().id(FORM_INPUT_ID))
        input.click()
        input.clearText()
        input.inputText("demo value")

        let submitButton = driver.findComponent(On().id(FORM_PRIMARY_BUTTON_ID))
        @Expect(submitButton.isClickable(), true)
        submitButton.click()

        let nextStepMarker = requireComponentAfterTransition(driver, NEXT_STEP_MARKER_ID, 400)
        @Expect(nextStepMarker.getText(), "Expected next step")
    } catch (e: BusinessException) {
        @Expect(false)
    }
}
```

## Pattern: `validation-error-state`

Use when invalid input should block progress and show explicit feedback.

```cangjie
@TestCase
func test_invalid_input_shows_error() {
    let driver = Driver.create()
    try {
        let input = driver.findComponent(On().id(FORM_INPUT_ID))
        input.click()
        input.clearText()
        input.inputText("bad")

        let submitButton = driver.findComponent(On().id(FORM_PRIMARY_BUTTON_ID))
        submitButton.click()

        let errorText = requireComponentAfterTransition(driver, FORM_ERROR_TEXT_ID, 300)
        @Expect(errorText.getText(), "Expected validation error")
        driver.assertComponentExist(On().id(FORM_INPUT_ID))
    } catch (e: BusinessException) {
        @Expect(false)
    }
}
```

## Pattern: `success-handoff-and-return`

Use when the flow should reach a success page, then re-open the smoke page for continued testing.

```cangjie
@TestCase
func test_success_handoff_and_reopen_smoke_page() {
    let driver = Driver.create()
    try {
        let primaryButton = driver.findComponent(On().id(LOGIN_PRIMARY_BUTTON_ID))
        primaryButton.click()

        let successMarker = requireComponentAfterTransition(driver, SUCCESS_MARKER_ID, 400)
        @Expect(successMarker.getText(), "Expected success title")

        driver.assertComponentExist(On().id(OPEN_UI_TEST_PAGE_ID))
        let reopenButton = driver.findComponent(On().id(OPEN_UI_TEST_PAGE_ID))
        reopenButton.click()

        let smokeButton = requireComponentAfterTransition(driver, UI_TEST_RUN_BUTTON_ID, 400)
        @Expect(smokeButton.isClickable(), true)
    } catch (e: BusinessException) {
        @Expect(false)
    }
}
```

## Pattern: `scroll-search-or-snapshot`

Use when the new UI depends on scrollable content or screenshot capture.

```cangjie
@TestCase
func test_scroll_search_and_snapshot() {
    let driver = Driver.create()
    try {
        let list = driver.findComponent(On().id(LIST_ID))
        let target = list.scrollSearch(On().id(TARGET_ITEM_ID))
        match (target) {
            case Some(item) => @Expect(item.getText(), "Expected item text")
            case _ => @Expect(false)
        }

        list.getSnapshot("/data/data/com.example.demo/cache/list.bmp")
    } catch (e: BusinessException) {
        @Expect(false)
    }
}
```

## Pattern: Outer XCTest Validation

Every pattern above still requires an outer Xcode UI Test shell.
Use the shell to:

1. launch with AbilityDelegator arguments
2. open the smoke page
3. tap `Run smoke check`
4. attach `after-open-ui-test-page`
5. attach `ui-test-smoke-result`

Do not move the real assertions out of `ohos.ui_test` and into XCTest.
