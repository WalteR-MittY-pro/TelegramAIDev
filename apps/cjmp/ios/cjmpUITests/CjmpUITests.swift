import XCTest
import ImageIO
import Vision

final class CjmpUITests: XCTestCase {
    private let loginSmokeEntryIdentifier = "slice1_login_smoke_entry"
    private let smokeClearSessionIdentifier = "slice3_smoke_clear_session"
    private let smokeRunIdentifier = "slice1_smoke_run"
    private let homeOpenSmokeIdentifier = "slice4_home_open_smoke"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRunSmokeCheckFromUiTestPage() throws {
        let app = XCUIApplication()
        launchApp(app)
        attachScreenshot(named: "post-launch", from: app)
        ensureLoginShellForSmoke(in: app)

        if !waitForSmokePage(in: app, timeout: 2) {
            tap(
                identifier: loginSmokeEntryIdentifier,
                label: "Open UI test page",
                fallback: CGVector(dx: 0.50, dy: 0.83),
                in: app
            )
            Thread.sleep(forTimeInterval: 3.0)
        }
        attachScreenshot(named: "after-open-ui-test-page", from: app)

        tap(
            identifier: smokeClearSessionIdentifier,
            label: "Clear local demo session",
            fallback: CGVector(dx: 0.50, dy: 0.75),
            in: app
        )
        Thread.sleep(forTimeInterval: 1.5)
        attachScreenshot(named: "after-clear-smoke-session", from: app)

        tap(
            identifier: smokeRunIdentifier,
            label: "Run smoke check",
            fallback: CGVector(dx: 0.50, dy: 0.82),
            in: app
        )
        Thread.sleep(forTimeInterval: 42.0)
        app.activate()
        attachScreenshot(named: "ui-test-smoke-result", from: app)

        var terminalStatus = waitForTerminalStatus(in: app, timeout: 12)
        if terminalStatus == nil,
           let fallbackSurface = waitForRecognizedText(["Back to smoke", "Alex Mason", "Loaded"], in: app, timeout: 2) {
            if fallbackSurface == "Alex Mason" {
                tap(
                    label: "Back",
                    fallback: CGVector(dx: 0.10, dy: 0.16),
                    in: app
                )
            } else {
                tap(
                    label: "Back to smoke",
                    fallback: CGVector(dx: 0.79, dy: 0.13),
                    in: app
                )
            }
            Thread.sleep(forTimeInterval: 2.0)
            app.activate()
            attachScreenshot(named: "after-return-to-smoke-page", from: app)
            terminalStatus = waitForTerminalStatus(in: app, timeout: 12)
        }

        guard let terminalStatus else {
            attachScreenshot(named: "smoke-terminal-missing", from: app)
            XCTFail("Smoke suite did not expose a terminal status")
            return
        }

        attachScreenshot(named: "smoke-terminal-\(terminalStatus.replacingOccurrences(of: " ", with: "-"))", from: app)
        XCTAssertEqual(terminalStatus, "Smoke suite passed")
    }

    private func launchApp(_ app: XCUIApplication) {
        app.launchArguments = [
            "test", "test",
            "bundleName", "bundleName",
            "moduleName", "moduleName",
            "unittest", "unittest",
            "timeout", "101",
        ]
        app.launch()
        waitForLaunchSettled()
        app.activate()

        let window = app.windows.element(boundBy: 0)
        XCTAssertTrue(window.waitForExistence(timeout: 15), "Main window did not appear")
    }

    private func ensureLoginShellForSmoke(in app: XCUIApplication) {
        if waitForRecognizedText(["Country / Region", "Phone number", "Open UI test page"], in: app, timeout: 6) != nil {
            return
        }

        if waitForRecognizedText(["Alex Mason", "Chats", "Settings"], in: app, timeout: 5) != nil {
            tap(
                identifier: homeOpenSmokeIdentifier,
                label: "Smoke",
                fallback: CGVector(dx: 0.86, dy: 0.18),
                in: app
            )
            XCTAssertTrue(
                waitForSmokePage(in: app, timeout: 8),
                "Could not reach the smoke page from the slice 6 home shell"
            )
            return
        }

        if waitForRecognizedText(["Back to login shell", "Restored local demo session", "Demo session ready"], in: app, timeout: 5) != nil {
            tap(
                label: "Back to login shell",
                fallback: CGVector(dx: 0.50, dy: 0.74),
                in: app
            )
            XCTAssertNotNil(
                waitForRecognizedText(["Country / Region", "Phone number", "Open UI test page"], in: app, timeout: 10),
                "Could not navigate from the placeholder back to the login shell"
            )
            return
        }

        if waitForSmokePage(in: app, timeout: 5) {
            tap(
                identifier: smokeClearSessionIdentifier,
                label: "Clear local demo session",
                fallback: CGVector(dx: 0.50, dy: 0.75),
                in: app
            )
            tap(
                label: "Back to login shell",
                fallback: CGVector(dx: 0.50, dy: 0.89),
                in: app
            )
            XCTAssertNotNil(
                waitForRecognizedText(["Country / Region", "Phone number", "Open UI test page"], in: app, timeout: 10),
                "Could not return from the smoke page to the login shell"
            )
            return
        }

        attachScreenshot(named: "unexpected-launch-surface", from: app)
        XCTFail("Could not determine a stable launch surface for smoke setup")
    }

    private func waitForTerminalStatus(in app: XCUIApplication, timeout: TimeInterval) -> String? {
        let terminalStatuses = [
            "Smoke suite passed",
            "Smoke suite failed",
            "Smoke suite crashed",
        ]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let recognized = recognizeText(from: app.screenshot(), candidates: terminalStatuses) {
                return recognized
            }

            let statusByIdentifier = app.descendants(matching: .any).matching(identifier: "slice1_smoke_status").firstMatch
            if statusByIdentifier.exists {
                let statusText = [statusByIdentifier.label, statusByIdentifier.value as? String]
                    .compactMap { $0 }
                    .joined(separator: "\n")
                for status in terminalStatuses where statusText.contains(status) {
                    return status
                }
            }

            let detailByIdentifier = app.descendants(matching: .any).matching(identifier: "slice1_smoke_detail").firstMatch
            if detailByIdentifier.exists {
                let detailText = [detailByIdentifier.label, detailByIdentifier.value as? String]
                    .compactMap { $0 }
                    .joined(separator: "\n")
                for status in terminalStatuses where detailText.contains(status) {
                    return status
                }
            }

            for status in terminalStatuses {
                if app.staticTexts[status].exists || app.otherElements[status].exists {
                    return status
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        return nil
    }

    private func waitForRecognizedText(_ texts: [String], in app: XCUIApplication, timeout: TimeInterval) -> String? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let recognized = recognizeText(from: app.screenshot(), candidates: texts) {
                return recognized
            }
            for text in texts where app.staticTexts[text].exists || app.buttons[text].exists || app.otherElements[text].exists {
                return text
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
        return nil
    }

    private func waitForIdentifier(_ identifier: String, in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        return element.waitForExistence(timeout: timeout)
    }

    private func waitForSmokePage(in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if waitForIdentifier(smokeRunIdentifier, in: app, timeout: 0.1) ||
                waitForIdentifier(smokeClearSessionIdentifier, in: app, timeout: 0.1) {
                return true
            }
            if waitForRecognizedText(["Run smoke check", "Clear local demo session"], in: app, timeout: 0.2) != nil {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }

    private func tap(identifier: String? = nil, label: String, fallback: CGVector, in app: XCUIApplication) {
        if let identifier {
            let identified = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            if identified.waitForExistence(timeout: 2) {
                identified.tap()
                return
            }
        }
        if app.buttons[label].waitForExistence(timeout: 2) {
            app.buttons[label].tap()
            return
        }
        if app.staticTexts[label].waitForExistence(timeout: 1) {
            app.staticTexts[label].tap()
            return
        }
        if app.otherElements[label].waitForExistence(timeout: 1) {
            app.otherElements[label].tap()
            return
        }

        let window = app.windows.element(boundBy: 0)
        window.coordinate(withNormalizedOffset: fallback).tap()
    }

    private func recognizeText(from screenshot: XCUIScreenshot, candidates: [String]) -> String? {
        if #available(iOS 13.0, *) {
            guard
                let imageSource = CGImageSourceCreateWithData(screenshot.pngRepresentation as CFData, nil),
                let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
            else {
                return nil
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                return nil
            }

            let normalizedText = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string.lowercased() }
                .joined(separator: "\n")

            for status in candidates {
                if normalizedText.contains(status.lowercased()) {
                    return status
                }
            }
        }
        return nil
    }

    private func waitForLaunchSettled() {
        Thread.sleep(forTimeInterval: 20.0)
    }

    private func attachScreenshot(named name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
