package ohos_app_cangjie_entry

internal import ohos.component.*
internal import ohos.state_manage.SubscriberManager
internal import ohos.state_manage.ObservedProperty
internal import ohos.state_manage.LocalStorage
internal import ohos.base.LengthProp
import ohos.router.Router
import ohos.state_macro_manage.Entry
import ohos.state_macro_manage.Component
import ohos.state_macro_manage.State
import std.time.*

let COLOR_APP_BACKGROUND = 0xFFF4F6F8
let COLOR_SURFACE = 0xFFFFFFFF
let COLOR_SURFACE_SUBTLE = 0xFFEEF2F6
let COLOR_TEXT_PRIMARY = 0xFF17212B
let COLOR_TEXT_SECONDARY = 0xFF5B6B7A
let COLOR_TEXT_MUTED = 0xFF8393A3
let COLOR_BRAND = 0xFF2AABEE
let COLOR_BRAND_SOFT = 0xFFE7F6FD
let COLOR_BORDER = 0xFFD9E2EC
let COLOR_STATUS_ERROR = 0xFFE5484D
let LOGIN_FORM_WIDTH = 92.percent
let LOGIN_FIELD_HORIZONTAL_PADDING = 16
let LOGIN_FIELD_VERTICAL_PADDING = 14
let LOGIN_FIELD_RADIUS = 16
let LOGIN_INPUT_HEIGHT = 28

let STARTUP_LOADING = "loading"
let STARTUP_LOGIN = "login"
let STARTUP_FAILURE = "failure"

let STARTUP_TITLE_COPY = "Loading Telegram..."
let STARTUP_BODY_COPY =
    "Preparing startup routing and shared design assets before the first-launch handoff."
let STARTUP_FAILURE_COPY =
    "Shared design assets failed to load. The app is using embedded fallback content."

let LOGIN_BRAND_TITLE = "Telegram"
let LOGIN_COUNTRY_LABEL = "Country / Region"
let LOGIN_COUNTRY_VALUE = "China"
let LOGIN_PHONE_LABEL = "Phone number"
let LOGIN_PHONE_VALUE = "+86"
let LOGIN_PHONE_HINT = "+86"
let LOGIN_KEEP_SIGNED_IN = "Keep me signed in on this device"
let LOGIN_CTA_LABEL = "Login"
let LOGIN_CONTINUE_LABEL = "Continue"
let LOGIN_VERIFICATION_TITLE = "Phone Number"
let LOGIN_VERIFICATION_INPUT_LABEL = "Verification Code"
let LOGIN_VERIFICATION_INPUT_HINT = "12345"
let LOGIN_VERIFICATION_HINT = "Demo verification stays local and keeps the login shell intact."
let LOGIN_VERIFICATION_CODE_HINT = "Enter any 5-digit demo code to continue."
let LOGIN_INVALID_INPUT_NOTICE = "Enter a valid demo phone number to continue."
let LOGIN_INVALID_CODE_NOTICE = "Enter a 5-digit demo code to continue."
let LOGIN_STEP_PHONE = "phone-entry"
let LOGIN_STEP_VERIFICATION = "verification"

let PLACEHOLDER_NOTICE =
    "This destination is intentionally scoped as a placeholder in the current MVP slice."

func isSmokeDemoLoginMode(mode: String): Bool {
    return mode == ENTRY_MODE_SMOKE_LOGIN_DEMO
}

func isValidDemoPhone(phoneNumber: String): Bool {
    return phoneNumber.startsWith("+86") && phoneNumber.size >= 14
}

func isValidDemoCode(verificationCode: String): Bool {
    return verificationCode.size >= 5
}

@Entry
@Component
class EntryView {
    @State
    var startupState: String = STARTUP_LOADING
    @State
    var phoneNumber: String = LOGIN_PHONE_VALUE
    @State
    var phoneLocalNumber: String = ""
    @State
    var keepSignedIn: Bool = true
    @State
    var loginStep: String = LOGIN_STEP_PHONE
    @State
    var verificationCode: String = ""
    @State
    var phoneNotice: String = ""
    @State
    var verificationNotice: String = ""
    @State
    var isSubmittingPhone: Bool = false
    @State
    var restoreNotice: String = ""
    @State
    var pendingRestoreRedirect: Bool = false
    @State
    var pendingUiTestRoute: Bool = false

    private var entryMode: String = ENTRY_MODE_DEFAULT
    private var didStartBootstrap: Bool = false

    protected override func aboutToAppear(): Unit {
        if (this.didStartBootstrap) {
            return
        }
        this.didStartBootstrap = true
        this.entryMode = this.resolveEntryMode()
        this.beginBootstrap()
    }

    func resolveEntryMode(): String {
        match (Router.getParams()) {
            case Some(mode) => return mode
            case None => return ENTRY_MODE_DEFAULT
        }
    }

    func beginBootstrap(): Unit {
        this.loginStep = LOGIN_STEP_PHONE
        this.phoneLocalNumber = if (isSmokeDemoLoginMode(this.entryMode)) {
            "13800138000"
        } else {
            ""
        }
        this.phoneNumber = "${LOGIN_PHONE_VALUE}${this.phoneLocalNumber}"
        this.verificationCode = ""
        this.phoneNotice = ""
        this.verificationNotice = ""
        this.restoreNotice = ""
        this.isSubmittingPhone = false
        this.pendingRestoreRedirect = false
        this.pendingUiTestRoute = false
        this.startupState = STARTUP_LOADING
        let modeCopy = this.entryMode
        let _ = spawn {
            sleep(700 * Duration.millisecond)
            if (modeCopy == ENTRY_MODE_SMOKE_FAILURE) {
                this.startupState = STARTUP_FAILURE
            } else if (isUiTestAutorunEnabled()) {
                this.startupState = STARTUP_LOGIN
                this.pendingUiTestRoute = true
            } else if (modeCopy == ENTRY_MODE_DEFAULT) {
                let restoreState = resolveDemoSessionRestoreState()
                if (restoreState == SESSION_RESTORE_RESTORED) {
                    this.startupState = STARTUP_LOGIN
                    this.pendingRestoreRedirect = true
                } else {
                    this.startupState = STARTUP_LOGIN
                    if (restoreState == SESSION_RESTORE_INVALID) {
                        this.restoreNotice = LOGIN_RESTORE_INVALID_NOTICE
                    }
                }
            } else {
                this.startupState = STARTUP_LOGIN
            }
        }
    }

    func enterHomeShell(
        phoneNumber!: String,
        restored!: Bool = false,
        persisted!: Bool = false
    ): Unit {
        updateCurrentDemoSessionPresentation(phoneNumber, restored, persisted)
        this.loginStep = LOGIN_STEP_PHONE
        this.verificationCode = ""
        this.phoneNotice = ""
        this.verificationNotice = ""
        this.isSubmittingPhone = false
        this.pendingRestoreRedirect = false
        Router.push(url: ROUTE_HOME_SHELL)
    }

    func handlePendingRestoreRedirect(): Unit {
        if (!this.pendingRestoreRedirect) {
            return
        }
        this.pendingRestoreRedirect = false
        this.enterHomeShell(
            phoneNumber: getCurrentDemoSessionPhoneNumber(),
            restored: true,
            persisted: true
        )
    }

    func handlePendingUiTestRoute(): Unit {
        if (!this.pendingUiTestRoute) {
            return
        }
        this.pendingUiTestRoute = false
        if (!tryMarkUiTestAutoRouteStarted()) {
            return
        }
        Router.push(url: ROUTE_UI_TEST_PAGE)
    }

    func submitPhoneEntry(): Unit {
        if (this.isSubmittingPhone) {
            return
        }
        this.phoneNotice = ""
        this.verificationNotice = ""
        this.restoreNotice = ""
        if (!isValidDemoPhone(this.phoneNumber)) {
            this.phoneNotice = LOGIN_INVALID_INPUT_NOTICE
            return
        }
        this.isSubmittingPhone = true
        let _ = spawn {
            sleep(350 * Duration.millisecond)
            this.isSubmittingPhone = false
            this.verificationCode = if (isSmokeDemoLoginMode(this.entryMode)) {
                "12345"
            } else {
                ""
            }
            this.verificationNotice = ""
            this.loginStep = LOGIN_STEP_VERIFICATION
        }
    }

    func returnToPhoneEntry(): Unit {
        this.loginStep = LOGIN_STEP_PHONE
        this.phoneNotice = ""
        this.verificationNotice = ""
        this.verificationCode = ""
        this.restoreNotice = ""
        this.isSubmittingPhone = false
    }

    func updatePhoneLocalNumber(value: String): Unit {
        this.phoneLocalNumber = value
        this.phoneNumber = "${LOGIN_PHONE_VALUE}${value}"
        this.phoneNotice = ""
        this.restoreNotice = ""
    }

    func submitVerification(): Unit {
        this.verificationNotice = ""
        if (!isValidDemoCode(this.verificationCode)) {
            this.verificationNotice = LOGIN_INVALID_CODE_NOTICE
            return
        }
        let didPersist = persistDemoSession(this.phoneNumber, this.keepSignedIn)
        this.enterHomeShell(phoneNumber: this.phoneNumber, persisted: didPersist)
    }

    func build() {
        if (this.startupState == STARTUP_LOADING) {
            Column(18) {
                Image("resources/base/media/app-mark.svg")
                    .id(ID_LOGIN_BRAND_MARK)
                    .width(88)
                    .height(88)

                LoadingProgress()
                    .id(ID_STARTUP_LOADING)
                    .color(COLOR_BRAND)
                    .foregroundColor(COLOR_BRAND)
                    .enableLoading(true)
                    .width(44)
                    .height(44)

                Text(STARTUP_TITLE_COPY)
                    .id(ID_STARTUP_TITLE)
                    .fontSize(24)
                    .fontColor(COLOR_TEXT_PRIMARY)
                    .fontWeight(FontWeight.Bold)

                Text(STARTUP_BODY_COPY)
                    .id(ID_STARTUP_BODY)
                    .fontSize(14)
                    .fontColor(COLOR_TEXT_SECONDARY)
                    .textAlign(TextAlign.Center)
                    .width(78.percent)
                    .maxLines(3)
            }
            .id(ID_STARTUP_ROOT)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(COLOR_APP_BACKGROUND)
            .padding(left: 24, right: 24, top: 24, bottom: 24)
        } else if (this.startupState == STARTUP_FAILURE) {
            Column(20) {
                Image("resources/base/media/app-mark.svg")
                    .width(72)
                    .height(72)

                Column(12) {
                    Text(LOGIN_BRAND_TITLE)
                        .fontSize(24)
                        .fontColor(COLOR_TEXT_PRIMARY)
                        .fontWeight(FontWeight.Bold)

                    Text(STARTUP_FAILURE_COPY)
                        .id(ID_FAILURE_BODY)
                        .fontSize(14)
                        .fontColor(COLOR_TEXT_SECONDARY)
                        .textAlign(TextAlign.Center)
                        .width(100.percent)
                }
                .alignItems(HorizontalAlign.Center)

                Button(LOGIN_CTA_LABEL)
                    .id(ID_FAILURE_PRIMARY)
                    .width(100.percent)
                    .height(52)
                    .backgroundColor(COLOR_BRAND)
                    .fontColor(COLOR_SURFACE)
                    .borderRadius(26)
                    .onClick({ =>
                        this.entryMode = ENTRY_MODE_DEFAULT
                        this.beginBootstrap()
                    })
            }
            .id(ID_FAILURE_ROOT)
            .width(100.percent)
            .height(100.percent)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(COLOR_APP_BACKGROUND)
            .padding(left: 24, right: 24, top: 24, bottom: 24)
        } else {
            Column(24) {
                Column(12) {
                    Image("resources/base/media/app-mark.svg")
                        .id(ID_LOGIN_BRAND_MARK)
                        .width(84)
                        .height(84)

                    Text(LOGIN_BRAND_TITLE)
                        .id(ID_LOGIN_BRAND_TITLE)
                        .fontSize(28)
                        .fontColor(COLOR_TEXT_PRIMARY)
                        .fontWeight(FontWeight.Bold)
                }
                .alignItems(HorizontalAlign.Center)

                Column(14) {
                    if (this.loginStep == LOGIN_STEP_PHONE) {
                        Column(14) {
                            if (!this.restoreNotice.isEmpty()) {
                                Text(this.restoreNotice)
                                    .id(ID_LOGIN_RESTORE_NOTICE)
                                    .fontSize(13)
                                    .fontColor(COLOR_TEXT_SECONDARY)
                                    .padding(left: 14, right: 14, top: 10, bottom: 10)
                                    .width(100.percent)
                                    .backgroundColor(COLOR_BRAND_SOFT)
                                    .borderRadius(16)
                            }

                            Column(6) {
                                Text(LOGIN_COUNTRY_LABEL)
                                    .fontSize(12)
                                    .fontColor(COLOR_TEXT_MUTED)
                                Row {
                                    Text(LOGIN_COUNTRY_VALUE)
                                        .id(ID_LOGIN_COUNTRY_VALUE)
                                        .fontSize(16)
                                        .fontColor(COLOR_TEXT_PRIMARY)
                                    Text("v")
                                        .fontSize(14)
                                        .fontColor(COLOR_TEXT_MUTED)
                                }
                                .justifyContent(FlexAlign.SpaceBetween)
                                .width(100.percent)
                            }
                            .alignItems(HorizontalAlign.Start)
                            .id(ID_LOGIN_COUNTRY_FIELD)
                            .width(100.percent)
                            .padding(
                                left: LOGIN_FIELD_HORIZONTAL_PADDING,
                                right: LOGIN_FIELD_HORIZONTAL_PADDING,
                                top: LOGIN_FIELD_VERTICAL_PADDING,
                                bottom: LOGIN_FIELD_VERTICAL_PADDING
                            )
                            .backgroundColor(COLOR_SURFACE)
                            .borderRadius(LOGIN_FIELD_RADIUS)

                            Column(6) {
                                Text(LOGIN_PHONE_LABEL)
                                    .fontSize(12)
                                    .fontColor(COLOR_TEXT_MUTED)
                                Row(8) {
                                    Text(LOGIN_PHONE_VALUE)
                                        .fontSize(16)
                                        .fontColor(COLOR_TEXT_PRIMARY)

                                    TextInput(text: this.phoneLocalNumber, placeholder: "")
                                        .id(ID_LOGIN_PHONE_INPUT)
                                        .layoutWeight(1)
                                        .height(LOGIN_INPUT_HEIGHT)
                                        .backgroundColor(0x00FFFFFF)
                                        .fontSize(16)
                                        .fontColor(COLOR_TEXT_PRIMARY)
                                        .textAlign(TextAlign.Start)
                                        .padding(left: 0, right: 0, top: 0, bottom: 0)
                                        .onChange({ value: String =>
                                            this.updatePhoneLocalNumber(value)
                                        })
                                }
                                .width(100.percent)
                            }
                            .alignItems(HorizontalAlign.Start)
                            .id(ID_LOGIN_PHONE_FIELD)
                            .width(100.percent)
                            .padding(
                                left: LOGIN_FIELD_HORIZONTAL_PADDING,
                                right: LOGIN_FIELD_HORIZONTAL_PADDING,
                                top: LOGIN_FIELD_VERTICAL_PADDING,
                                bottom: LOGIN_FIELD_VERTICAL_PADDING
                            )
                            .backgroundColor(COLOR_SURFACE)
                            .borderRadius(LOGIN_FIELD_RADIUS)

                            if (!this.phoneNotice.isEmpty()) {
                                Text(this.phoneNotice)
                                    .id(ID_LOGIN_NOTICE)
                                    .fontSize(13)
                                    .fontColor(COLOR_STATUS_ERROR)
                                    .width(100.percent)
                            }

                            Row(10) {
                                Toggle(ToggleType.CheckboxType, isOn: this.keepSignedIn)
                                    .id(ID_LOGIN_KEEP_SIGNED_IN)
                                    .size(width: 22, height: 22)
                                    .selectedColor(COLOR_BRAND)
                                    .onChange({ isOn: Bool =>
                                        this.keepSignedIn = isOn
                                    })
                                Text(LOGIN_KEEP_SIGNED_IN)
                                    .fontSize(14)
                                    .fontColor(COLOR_TEXT_SECONDARY)
                                    .layoutWeight(1)
                            }
                            .width(100.percent)

                            Button(if (this.isSubmittingPhone) {
                                "Checking..."
                            } else {
                                LOGIN_CONTINUE_LABEL
                            })
                                .id(ID_LOGIN_PRIMARY_CTA)
                                .width(100.percent)
                                .height(54)
                                .backgroundColor(COLOR_BRAND)
                                .fontColor(COLOR_SURFACE)
                                .fontWeight(FontWeight.Bold)
                                .borderRadius(27)
                                .onClick({ =>
                                    this.submitPhoneEntry()
                                })
                        }
                        .width(LOGIN_FORM_WIDTH)
                    } else {
                        Column(14) {
                            Column(8) {
                                Text(LOGIN_VERIFICATION_TITLE)
                                    .id(ID_LOGIN_VERIFICATION_TITLE)
                                    .fontSize(16)
                                    .fontColor(COLOR_TEXT_PRIMARY)
                                    .fontWeight(FontWeight.Bold)
                                Text(this.phoneNumber)
                                    .id(ID_LOGIN_VERIFICATION_PHONE)
                                    .fontSize(14)
                                    .fontColor(COLOR_TEXT_PRIMARY)
                                    .fontWeight(FontWeight.Medium)
                            }
                            .alignItems(HorizontalAlign.Start)
                            .id(ID_LOGIN_VERIFICATION_ROOT)
                            .width(100.percent)
                            .padding(
                                left: LOGIN_FIELD_HORIZONTAL_PADDING,
                                right: LOGIN_FIELD_HORIZONTAL_PADDING,
                                top: LOGIN_FIELD_VERTICAL_PADDING,
                                bottom: LOGIN_FIELD_VERTICAL_PADDING
                            )
                            .backgroundColor(COLOR_SURFACE)
                            .borderRadius(LOGIN_FIELD_RADIUS)

                            Column(6) {
                                Text(LOGIN_VERIFICATION_INPUT_LABEL)
                                    .width(100.percent)
                                    .fontSize(15)
                                    .fontColor(COLOR_TEXT_PRIMARY)
                                    .fontWeight(FontWeight.Bold)
                                    .textAlign(TextAlign.Start)
                                Row {
                                    TextInput(text: this.verificationCode, placeholder: "")
                                        .id(ID_LOGIN_VERIFICATION_INPUT)
                                        .layoutWeight(1)
                                        .height(LOGIN_INPUT_HEIGHT)
                                        .backgroundColor(0x00FFFFFF)
                                        .fontSize(16)
                                        .fontColor(COLOR_TEXT_PRIMARY)
                                        .textAlign(TextAlign.Start)
                                        .padding(left: 0, right: 0, top: 0, bottom: 0)
                                        .onChange({ value: String =>
                                            this.verificationCode = value
                                            this.verificationNotice = ""
                                        })
                                }
                                .width(100.percent)
                            }
                            .alignItems(HorizontalAlign.Start)
                            .width(100.percent)
                            .padding(
                                left: LOGIN_FIELD_HORIZONTAL_PADDING,
                                right: LOGIN_FIELD_HORIZONTAL_PADDING,
                                top: LOGIN_FIELD_VERTICAL_PADDING,
                                bottom: LOGIN_FIELD_VERTICAL_PADDING
                            )
                            .backgroundColor(COLOR_SURFACE)
                            .borderRadius(LOGIN_FIELD_RADIUS)

                            Text(LOGIN_VERIFICATION_HINT)
                                .id(ID_LOGIN_VERIFICATION_HINT)
                                .fontSize(13)
                                .fontColor(COLOR_TEXT_SECONDARY)
                                .width(100.percent)

                            Text(LOGIN_VERIFICATION_CODE_HINT)
                                .fontSize(13)
                                .fontColor(COLOR_TEXT_SECONDARY)
                                .width(100.percent)

                            if (!this.verificationNotice.isEmpty()) {
                                Text(this.verificationNotice)
                                    .id(ID_LOGIN_VERIFICATION_NOTICE)
                                    .fontSize(13)
                                    .fontColor(COLOR_STATUS_ERROR)
                                    .width(100.percent)
                            }

                            Button(LOGIN_CTA_LABEL)
                                .id(ID_LOGIN_VERIFICATION_PRIMARY)
                                .width(100.percent)
                                .height(54)
                                .backgroundColor(COLOR_BRAND)
                                .fontColor(COLOR_SURFACE)
                                .fontWeight(FontWeight.Bold)
                                .borderRadius(27)
                                .onClick({ =>
                                    this.submitVerification()
                                })

                            Button("Edit phone number")
                                .id(ID_LOGIN_VERIFICATION_BACK)
                                .width(100.percent)
                                .height(44)
                                .backgroundColor(COLOR_SURFACE_SUBTLE)
                                .fontColor(COLOR_TEXT_PRIMARY)
                                .borderRadius(22)
                                .onClick({ =>
                                    this.returnToPhoneEntry()
                                })
                        }
                        .width(LOGIN_FORM_WIDTH)
                    }

                }
                .width(100.percent)
            }
            .id(ID_LOGIN_ROOT)
            .width(100.percent)
            .height(100.percent)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .padding(left: 24, right: 24, top: 24, bottom: 24)
            .backgroundColor(COLOR_APP_BACKGROUND)
            .onAppear({ =>
                this.handlePendingRestoreRedirect()
                this.handlePendingUiTestRoute()
            })
        }
    }
}
