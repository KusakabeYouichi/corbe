import XCTest

// App Store のスクリーンショットを撮る(テストではない)。環境変数 CORBE_SCREENSHOT_DIR があるときだけ動く。
// xcodebuild には TEST_RUNNER_CORBE_SCREENSHOT_DIR=<出力先> で渡す(手順は appstore/screenshots-plan.md)
final class CorbeScreenshotUITests: XCTestCase {
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        guard let path = ProcessInfo.processInfo.environment["CORBE_SCREENSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("CORBE_SCREENSHOT_DIR が無いので撮らない")
        }
        outputDirectory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }

    func testShoot01_ComponentSearch() throws {
        let app = launch()
        selectPosition(0, "偏", app: app)
        selectRadical(0, "木 き", app: app)
        XCTAssertTrue(element("kanji.村", in: app).waitForExistence(timeout: 10))
        try save("01-corbe", app: app)
    }

    func testShoot02_RadicalList() throws {
        let app = launch()
        selectPosition(0, "偏", app: app)
        app.buttons["componentForm.0"].firstMatch.tap()
        XCTAssertTrue(element("componentFormList.0", in: app).waitForExistence(timeout: 5))
        try save("02-radical-list", app: app)
    }

    func testShoot03_Kangxi() throws {
        let app = launch()
        app.tabBars.buttons["Kangxi"].tap()
        element("radicalCategory.偏", in: app).tap()
        let ki = element("radicalForm.75-木", in: app)
        XCTAssertTrue(ki.waitForExistence(timeout: 10))
        ki.tap()
        XCTAssertTrue(element("kanji.村", in: app).waitForExistence(timeout: 10))
        try save("03-kangxi", app: app)
    }

    func testShoot04_Reading() throws {
        let app = launch()
        app.tabBars.buttons["japonaise"].tap()
        let field = app.textFields["readingField.kun"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("むら")
        app.buttons["keyboardDone"].firstMatch.tap()
        XCTAssertTrue(element("kanji.村", in: app).waitForExistence(timeout: 10))
        try save("04-lecture", app: app)
    }

    func testShoot05_Detail() throws {
        let app = launch()
        selectPosition(0, "偏", app: app)
        selectRadical(0, "木 き", app: app)
        selectPosition(1, "旁", app: app)
        selectRadical(1, "寸 すん", app: app)
        let mura = element("kanji.村", in: app)
        XCTAssertTrue(mura.waitForExistence(timeout: 10))
        mura.press(forDuration: 1.0)
        XCTAssertTrue(element("detail.category", in: app).waitForExistence(timeout: 5))
        try save("05-detail", app: app)
    }

    // MARK: - 補助

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let loading = element("loadingIndicator", in: app)
        let deadline = Date().addingTimeInterval(15)
        while loading.exists, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
        }
        return app
    }

    private func save(_ name: String, app: XCUIApplication) throws {
        // 吹き出しやスクロールの動きが止まるのを待つ
        Thread.sleep(forTimeInterval: 1.0)
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try data.write(to: outputDirectory.appendingPathComponent("\(name).png"))
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func selectPosition(_ index: Int, _ position: String, app: XCUIApplication) {
        let picker = app.buttons["componentPosition.\(index)"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let item = app.buttons.matching(NSPredicate(format: "label == %@ AND NOT (identifier BEGINSWITH 'componentPosition')", position)).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()
    }

    private func selectRadical(_ index: Int, _ label: String, app: XCUIApplication) {
        app.buttons["componentForm.\(index)"].firstMatch.tap()
        let list = element("componentFormList.\(index)", in: app)
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let item = list.buttons[label].firstMatch
        for _ in 0..<40 where !(item.exists && !item.frame.isEmpty && list.frame.contains(item.frame)) {
            let center = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let pullDown = item.exists && !item.frame.isEmpty && item.frame.minY < list.frame.minY
            center.press(forDuration: 0.05, thenDragTo: center.withOffset(CGVector(dx: 0, dy: pullDown ? 120 : -120)))
        }
        item.tap()
        XCTAssertTrue(list.waitForNonExistence(timeout: 5))
    }
}
