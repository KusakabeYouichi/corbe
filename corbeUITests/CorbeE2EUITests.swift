import XCTest

// c01-tests.md の E1–E8 を XCUITest で行う。
// クリップボードはテストランナーから UIPasteboard.general で読み書きする(régu の reguUITests と同じ)。
// 各テストは起動し直しから始め、前のテストの状態に依存しない
@MainActor
final class CorbeE2EUITests: XCTestCase {
    private static let allowPasteLabels = ["ペーストを許可", "Allow Paste"]
    private static let sentinel = "corbe-ui-test-sentinel"

    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
    }

    func testE1_LaunchShowsFourTabs() {
        let app = launch()

        for title in ["corbé", "Kangxi", "chinoise", "japonaise"] {
            XCTAssertTrue(app.tabBars.buttons[title].waitForExistence(timeout: 5), "タブ \(title) が無い")
        }
    }

    func testE2_ComponentRowsFindMuraAndTapCopies() {
        let app = launch()
        setRow(0, position: "偏", text: "木", app: app)
        setRow(1, position: "旁", text: "寸", app: app)
        let mura = kanji("村", app: app)
        XCTAssertTrue(mura.waitForExistence(timeout: 10), "[偏 木][旁 寸] の結果に 村 が無い")
        UIPasteboard.general.string = Self.sentinel

        mura.tap()

        XCTAssertTrue(element("copiedBadge", in: app).waitForExistence(timeout: 3), "「コピーしました」が出ない")
        XCTAssertEqual(element("copiedBadge", in: app).label, "「村」をコピーしました")
        XCTAssertEqual(readPasteboard(), "村")
    }

    func testE3_LongPressShowsDetailWithoutCopying() {
        let app = launch()
        UIPasteboard.general.string = Self.sentinel
        setRow(0, position: "偏", text: "木", app: app)
        setRow(1, position: "旁", text: "寸", app: app)
        let mura = kanji("村", app: app)
        XCTAssertTrue(mura.waitForExistence(timeout: 10))

        mura.press(forDuration: 1.0)

        XCTAssertTrue(element("detail.on", in: app).waitForExistence(timeout: 5), "詳細が出ない")
        XCTAssertEqual(element("detail.on", in: app).label, "ソン")
        XCTAssertEqual(element("detail.kun", in: app).label, "むら")
        XCTAssertEqual(element("detail.codePoint", in: app).label, "U+6751")
        XCTAssertEqual(element("detail.kuten", in: app).label, "34-28")
        XCTAssertFalse(element("copiedBadge", in: app).exists, "長押しでコピーされた")
        XCTAssertEqual(readPasteboard(), Self.sentinel)
    }

    func testE4_KangxiRadicalGridCopiesMura() {
        let app = launch()
        app.tabBars.buttons["Kangxi"].tap()
        element("radicalCategory.偏", in: app).tap()
        let ki = element("radicalForm.75-木", in: app)
        XCTAssertTrue(ki.waitForExistence(timeout: 10), "偏 の一覧に 木 が無い")
        scrollUntilHittable(ki, in: app)
        ki.tap()
        let mura = kanji("村", app: app)
        scrollUntilHittable(mura, in: app)
        UIPasteboard.general.string = Self.sentinel

        mura.tap()

        XCTAssertTrue(element("copiedBadge", in: app).waitForExistence(timeout: 3), "「コピーしました」が出ない")
        XCTAssertEqual(readPasteboard(), "村")
    }

    func testE5_ReadingTabsFindAndCopyMura() {
        let app = launch()
        app.tabBars.buttons["chinoise"].tap()
        let onField = app.textFields["readingField.on"]
        XCTAssertTrue(onField.waitForExistence(timeout: 5))
        onField.tap()
        onField.typeText("そん")
        dismissKeyboard(app: app)
        let mura = kanji("村", app: app)
        XCTAssertTrue(mura.waitForExistence(timeout: 10), "chinoise そん の結果に 村 が無い")
        scrollUntilHittable(mura, in: app)
        UIPasteboard.general.string = Self.sentinel
        mura.tap()
        XCTAssertEqual(readPasteboard(), "村")

        app.tabBars.buttons["japonaise"].tap()
        let kunField = app.textFields["readingField.kun"]
        XCTAssertTrue(kunField.waitForExistence(timeout: 5))
        kunField.tap()
        kunField.typeText("むら")
        dismissKeyboard(app: app)
        let kunMura = kanji("村", app: app)
        XCTAssertTrue(kunMura.waitForExistence(timeout: 10), "japonaise むら の結果に 村 が無い")
        scrollUntilHittable(kunMura, in: app)
        UIPasteboard.general.string = Self.sentinel

        kunMura.tap()

        XCTAssertEqual(readPasteboard(), "村")
    }

    func testE6_LicensesShowUnicodeAndBabelStone() {
        let app = launch()

        app.buttons["licensesButton"].firstMatch.tap()

        XCTAssertTrue(element("licensesView", in: app).waitForExistence(timeout: 5), "ライセンス画面が出ない")
        XCTAssertTrue(text(containing: "UNICODE LICENSE V3", app: app).waitForExistence(timeout: 5))
        XCTAssertTrue(text(containing: "BabelStone IDS", app: app).exists)
        XCTAssertTrue(text(containing: "without asking permission or providing attribution", app: app).exists)
    }

    func testE7_EmptyInputShowsHintOnEveryTab() {
        let app = launch()

        for title in ["corbé", "Kangxi", "chinoise", "japonaise"] {
            app.tabBars.buttons[title].tap()
            XCTAssertTrue(element("emptyHint", in: app).waitForExistence(timeout: 10), "\(title) に空状態のヒントが無い")
        }
    }

    func testE8_LandscapeKeepsInputAndFirstResultHittable() {
        let app = launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        let field = app.textFields["componentText.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("木")
        dismissKeyboard(app: app)
        let first = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'kanji.'")).firstMatch

        XCTAssertTrue(first.waitForExistence(timeout: 10), "結果が出ない")
        XCTAssertTrue(field.isHittable, "横向きで入力欄が押せない")
        XCTAssertTrue(first.isHittable, "横向きで結果の 1 字目が押せない")
    }

    // MARK: - 起動

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-corbeUITestBadgeSeconds", "5"]
        app.launch()
        // 索引の読み込み中表示が消えるまで待つ
        let loading = element("loadingIndicator", in: app)
        let deadline = Date().addingTimeInterval(15)
        while loading.exists, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
        }
        return app
    }

    // MARK: - 画面操作

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func kanji(_ character: String, app: XCUIApplication) -> XCUIElement {
        element("kanji.\(character)", in: app)
    }

    private func text(containing fragment: String, app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
    }

    private func setRow(_ index: Int, position: String, text: String, app: XCUIApplication) {
        let picker = app.buttons["componentPosition.\(index)"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "\(index) 行目の位置が無い")
        picker.tap()
        let item = app.buttons[position].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "位置のメニューに \(position) が無い")
        item.tap()
        let field = app.textFields["componentText.\(index)"]
        field.tap()
        field.typeText(text)
        XCTAssertEqual(field.value as? String, text)
        dismissKeyboard(app: app)
    }

    private func dismissKeyboard(app: XCUIApplication) {
        guard app.keyboards.firstMatch.exists else {
            return
        }
        let done = app.keyboards.buttons.matching(NSPredicate(format: "label IN %@", ["完了", "Done", "done", "改行", "Return", "return"])).firstMatch
        if done.exists {
            done.tap()
        }
    }

    private func scrollUntilHittable(_ target: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<15 {
            if target.exists, target.isHittable {
                return
            }
            app.scrollViews.firstMatch.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(target.isHittable, "\(target) が画面に出ない")
    }

    // MARK: - クリップボード

    // ランナー自身の読み込みにもペースト許可が出うるので、読み込みは別スレッドで行い、その間アラートを見張る(régu と同じ)
    private func readPasteboard() -> String? {
        let box = PasteboardBox()
        DispatchQueue.global().async {
            box.finish(with: UIPasteboard.general.string)
        }
        let deadline = Date().addingTimeInterval(30)
        while !box.isFinished {
            allowPasteIfPrompted()
            if Date() > deadline {
                XCTFail("クリップボードの読み込みが終わらない")
                return nil
            }
            Thread.sleep(forTimeInterval: 0.3)
        }
        return box.value
    }

    private func allowPasteIfPrompted() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in Self.allowPasteLabels {
            let button = springboard.buttons[label]
            if button.exists {
                button.tap()
                return
            }
        }
    }
}

private final class PasteboardBox: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false
    private var stored: String?

    var isFinished: Bool {
        lock.withLock { finished }
    }

    var value: String? {
        lock.withLock { stored }
    }

    func finish(with value: String?) {
        lock.withLock {
            stored = value
            finished = true
        }
    }
}
