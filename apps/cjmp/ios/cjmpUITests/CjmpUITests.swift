import XCTest
import Vision

final class CjmpUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRunSmokeCheckFromUiTestPage() throws {
        let app = XCUIApplication()
        launchApp(app)
        attachScreenshot(named: "post-launch", from: app)

        guard let terminalStatus = waitForTerminalStatus(in: app, timeout: 120) else {
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

    private func waitForTerminalStatus(in app: XCUIApplication, timeout: TimeInterval) -> String? {
        let terminalStatuses = [
            "Smoke suite passed",
            "Smoke suite failed",
            "Smoke suite crashed",
        ]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let recognized = recognizeText(from: app.screenshot())
            for status in terminalStatuses {
                if recognized.contains(status) {
                    return status
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(2.0))
        }
        return nil
    }

    private func recognizeText(from screenshot: XCUIScreenshot) -> String {
        guard let cgImage = screenshot.image.cgImage else { return "" }
        var recognizedText = ""
        if #available(iOS 13.0, *) {
            let request = VNRecognizeTextRequest { request, _ in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
            }
            request.recognitionLevel = .accurate
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                return ""
            }
        }
        return recognizedText
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
