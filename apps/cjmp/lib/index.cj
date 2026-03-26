package ohos_app_cangjie_entry

internal import cjmp.net.connection.*
internal import ohos.base.LengthProp
internal import ohos.component.*
internal import ohos.state_manage.SubscriberManager
internal import ohos.state_manage.ObservedProperty
internal import ohos.state_manage.LocalStorage
internal import ohos.ui_test.*
import ohos.state_macro_manage.Entry
import ohos.state_macro_manage.Component
import ohos.state_macro_manage.State

let ROUTE_BOOTSTRAP = "bootstrap-loading"
let ROUTE_LOGIN = "login-handoff"
let ROUTE_STARTUP_FAILURE = "startup-failure"
let ROUTE_AUTH_PLACEHOLDER = "authenticated-placeholder"

let COPY_BOOTSTRAP_TITLE = "Loading Telegram Demo..."
let COPY_BOOTSTRAP_BODY = "Preparing startup routing and shared design assets before the first-launch handoff."
let COPY_BOOTSTRAP_FAILURE_NOTICE = "Shared design assets failed to load. The app is using embedded fallback content."
let COPY_LOGIN_BRAND_TITLE = "Telegram Demo"
let COPY_LOGIN_HEADLINE = "Start with your phone number"
let COPY_LOGIN_BODY = "Slice #1 startup routing only. Demo verification is intentionally deferred to slice #2."
let COPY_LOGIN_CONTINUE = "Continue"
let COPY_PLACEHOLDER_TITLE = "Authenticated Placeholder"
let COPY_PLACEHOLDER_BODY = "This is an intentional slice #1 placeholder. Home shell and chat list are not implemented yet."

@Entry
@Component
class EntryView {
    @State
    var route: String = ROUTE_LOGIN
    @State
    var simulateStartupFailure: Bool = false

    func routeTitle(): String {
        if (route == ROUTE_BOOTSTRAP) {
            COPY_BOOTSTRAP_TITLE
        } else if (route == ROUTE_STARTUP_FAILURE) {
            "Startup check failed"
        } else if (route == ROUTE_AUTH_PLACEHOLDER) {
            COPY_PLACEHOLDER_TITLE
        } else {
            COPY_LOGIN_HEADLINE
        }
    }

    func routeBody(): String {
        if (route == ROUTE_BOOTSTRAP) {
            COPY_BOOTSTRAP_BODY
        } else if (route == ROUTE_STARTUP_FAILURE) {
            COPY_BOOTSTRAP_FAILURE_NOTICE
        } else if (route == ROUTE_AUTH_PLACEHOLDER) {
            COPY_PLACEHOLDER_BODY
        } else {
            COPY_LOGIN_BODY
        }
    }

    func primaryLabel(): String {
        if (route == ROUTE_BOOTSTRAP) {
            "Finish startup check"
        } else if (route == ROUTE_STARTUP_FAILURE) {
            "Use login fallback"
        } else if (route == ROUTE_AUTH_PLACEHOLDER) {
            "Back to login"
        } else {
            COPY_LOGIN_CONTINUE
        }
    }

    func secondaryLabel(): String {
        if (route == ROUTE_BOOTSTRAP) {
            "Force startup failure notice"
        } else if (route == ROUTE_STARTUP_FAILURE) {
            "Retry startup check"
        } else if (route == ROUTE_AUTH_PLACEHOLDER) {
            "Show startup failure notice"
        } else {
            "Show startup failure notice"
        }
    }

    func runStartupCheck(): Unit {
        route = ROUTE_BOOTSTRAP
        if (simulateStartupFailure) {
            route = ROUTE_STARTUP_FAILURE
        } else {
            route = ROUTE_LOGIN
        }
    }

    func recoverToLoginFallback(): Unit {
        simulateStartupFailure = false
        route = ROUTE_LOGIN
    }

    func forceFailureAndCheck(): Unit {
        simulateStartupFailure = true
        runStartupCheck()
    }

    func retryStartupAfterFailure(): Unit {
        simulateStartupFailure = false
        runStartupCheck()
    }

    func onPrimaryAction(): Unit {
        if (route == ROUTE_BOOTSTRAP) {
            runStartupCheck()
        } else if (route == ROUTE_STARTUP_FAILURE) {
            recoverToLoginFallback()
        } else if (route == ROUTE_AUTH_PLACEHOLDER) {
            route = ROUTE_LOGIN
        } else {
            route = ROUTE_AUTH_PLACEHOLDER
        }
    }

    func onSecondaryAction(): Unit {
        if (route == ROUTE_BOOTSTRAP) {
            forceFailureAndCheck()
        } else if (route == ROUTE_STARTUP_FAILURE) {
            retryStartupAfterFailure()
        } else {
            forceFailureAndCheck()
        }
    }

    func build() {
        Row {
            Column {
                Text(COPY_LOGIN_BRAND_TITLE).fontSize(30).height(60)
                Text(routeTitle()).fontSize(24).height(60)
                Text(routeBody()).fontSize(16).height(140)
                Button(primaryLabel()).onClick {
                    =>
                        onPrimaryAction()
                }.fontSize(20).height(64)
                Button(secondaryLabel()).onClick {
                    =>
                        onSecondaryAction()
                }.fontSize(16).height(56)
            }.width(100.percent)
        }.height(100.percent)
    }
}
