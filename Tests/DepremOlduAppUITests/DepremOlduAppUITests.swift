import XCTest

@MainActor
final class DepremOlduAppUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchApp(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func anyElement(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func testEarthquakeListShowsContentAndLegend() {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["Küçük"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Orta"].exists)
        XCTAssertTrue(app.staticTexts["Büyük"].exists)
        XCTAssertTrue(app.staticTexts["Çok Büyük"].exists)

        let row = app.buttons["earthquake.row.ui-1"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(row.label.contains("SUGUL-DARENDE"))
        XCTAssertTrue(row.label.contains("2.0"))
    }

    func testLocationSheetOpensFromARow() {
        let app = launchApp()

        let row = app.buttons["earthquake.row.ui-1"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()

        XCTAssertTrue(app.navigationBars["Deprem Konumu"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Derinlik:"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Koordinat:"].exists)

        app.buttons["Kapat"].tap()
        XCTAssertFalse(app.navigationBars["Deprem Konumu"].waitForExistence(timeout: 2))
    }

    func testMapTabShowsLegendAndFaultToggle() {
        let app = launchApp()

        app.tabBars.buttons["Harita"].tap()

        XCTAssertTrue(anyElement(app, "map.legend").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["SON 500 DEPREM"].exists)

        let toggle = app.buttons["map.fault-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.value as? String, "Kapalı")

        toggle.tap()
        XCTAssertTrue(anyElement(app, "map.legend").waitForExistence(timeout: 5))
    }

    func testAwarenessTabShowsCards() {
        let app = launchApp()

        app.tabBars.buttons["Afet Bilinci"].tap()

        XCTAssertTrue(
            app.buttons["Deprem Anında Yapmanız Gerekenler"].waitForExistence(timeout: 10)
        )

        let lastCard = app.buttons["Türkiye Diri Fay Haritası (MTA)"]
        var attempts = 0
        while !lastCard.exists, attempts < 10 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(lastCard.exists)
    }

    func testRefreshButtonKeepsListVisible() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["earthquake.row.ui-1"].waitForExistence(timeout: 10))
        app.buttons["toolbar.refresh"].tap()
        XCTAssertTrue(app.buttons["earthquake.row.ui-1"].waitForExistence(timeout: 10))
    }

    func testFailureStateOffersRetry() {
        let app = launchApp(arguments: ["-depremoldu-ui-failure"])

        XCTAssertTrue(app.buttons["error.retry"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.staticTexts["Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin."].exists
        )
    }

    func testEmptyStateShowsZeroCount() {
        let app = launchApp(arguments: ["-depremoldu-ui-empty"])

        let count = app.staticTexts["earthquake.count"]
        XCTAssertTrue(count.waitForExistence(timeout: 10))
        XCTAssertEqual(count.label, "0 deprem")
    }

    func testAboutSheetOpens() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["earthquake.row.ui-1"].waitForExistence(timeout: 10))
        app.buttons["Hakkında"].tap()

        XCTAssertTrue(app.navigationBars["Hakkında"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Veri Kaynakları"].exists)
        XCTAssertTrue(app.staticTexts["Kandilli Rasathanesi (KOERI)"].exists)
        app.buttons["Kapat"].tap()
        XCTAssertFalse(app.navigationBars["Hakkında"].waitForExistence(timeout: 2))
    }
}
