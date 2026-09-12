import XCTest

/// Generates the App Store screenshots from the live API.
///
/// The test is skipped by default so the deterministic UI suite stays offline.
/// Run it explicitly with `CAPTURE_STORE_SCREENSHOTS=1`:
///
///     CAPTURE_STORE_SCREENSHOTS=1 xcodebuild test \
///       -only-testing:DepremOlduAppUITests/StoreScreenshotCaptureTests ...
@MainActor
final class StoreScreenshotCaptureTests: XCTestCase {
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func listRow(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'earthquake.row.'")
        ).firstMatch
    }

    @discardableResult
    private func openListWithRetry(_ app: XCUIApplication) -> XCUIElement {
        let row = listRow(in: app)
        for attempt in 0..<4 where !row.exists {
            if attempt > 0 {
                app.tabBars.buttons["Son Depremler"].tap()
            }
            _ = row.waitForExistence(timeout: 15)
        }
        return row
    }

    func testCaptureStoreScreenshots() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["CAPTURE_STORE_SCREENSHOTS"] == "1",
            "Set CAPTURE_STORE_SCREENSHOTS=1 to capture App Store screenshots."
        )
        let app = XCUIApplication()
        app.launchArguments = ["-depremoldu-ui-live"]
        app.launch()

        let firstRow = listRow(in: app)
        XCTAssertTrue(firstRow.waitForExistence(timeout: 45))
        sleep(2)
        capture(app, "01-list")

        app.tabBars.buttons["Harita"].tap()
        sleep(6)
        let toggle = app.buttons["map.fault-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 20))
        var attempts = 0
        while (!toggle.isEnabled || toggle.value as? String != "Kapalı"), attempts < 20 {
            sleep(1)
            attempts += 1
        }
        toggle.tap()
        sleep(18)
        capture(app, "02-map-faults")

        app.tabBars.buttons["Son Depremler"].tap()
        let row = openListWithRetry(app)
        XCTAssertTrue(row.exists, "Liste satırları yüklenemedi")
        row.tap()
        XCTAssertTrue(app.navigationBars["Deprem Konumu"].waitForExistence(timeout: 10))
        sleep(15)
        capture(app, "03-location")
        app.buttons["Kapat"].tap()
        XCTAssertTrue(
            app.navigationBars["Deprem Konumu"].waitForNonExistence(timeout: 15),
            "Deprem Konumu sheet'i kapanmadı"
        )

        app.tabBars.buttons["Afet Bilinci"].tap()
        sleep(3)
        capture(app, "04-awareness")

        app.tabBars.buttons["Son Depremler"].tap()
        XCTAssertTrue(app.buttons["Hakkında"].waitForExistence(timeout: 15))
        app.buttons["Hakkında"].tap()
        XCTAssertTrue(
            app.navigationBars["Hakkında"].waitForExistence(timeout: 20),
            "Hakkında ekranı açılmadı"
        )
        sleep(1)
        capture(app, "05-about")
    }
}
