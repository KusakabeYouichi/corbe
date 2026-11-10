import XCTest

// c01-tests.md の E1・E3–E8 と c02-tests.md の G1–G4・G6・G6b・G7・G8a/b・G9–G12 を XCUITest で行う(E2 は G3 に置き換え)。
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

    func testG1_LaunchShowsTexteLibreWithFreeTextOnEveryRow() {
        let app = launch()

        for index in 0..<3 {
            XCTAssertTrue(app.buttons["componentPosition.\(index)"].firstMatch.waitForExistence(timeout: 5), "\(index) 行目の位置が無い")
            XCTAssertEqual(app.buttons["componentPosition.\(index)"].firstMatch.label, "texte libre", "\(index) 行目が texte libre でない")
            XCTAssertTrue(app.textFields["componentText.\(index)"].exists, "\(index) 行目に自由入力欄が無い")
            XCTAssertFalse(element("componentForm.\(index)", in: app).exists, "\(index) 行目に部首のプルダウンがある")
        }
    }

    func testG2_PositionHenShowsRadicalMenuInsteadOfFreeText() {
        let app = launch()

        selectPosition(0, "偏", app: app)

        let form = app.buttons["componentForm.0"].firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 5), "偏 にしても部首のプルダウンが出ない")
        XCTAssertTrue(form.label.contains("選択"), "未選択の表示が「選択」でない: \(form.label)")
        XCTAssertFalse(app.textFields["componentText.0"].exists, "偏 なのに自由入力欄がある")
    }

    func testG3_RadicalMenusFindMuraAndTapCopies() {
        let app = launch()
        selectPosition(0, "偏", app: app)
        selectRadical(0, "木 き", app: app)
        selectPosition(1, "旁", app: app)
        selectRadical(1, "寸 すん", app: app)
        let mura = kanji("村", app: app)
        XCTAssertTrue(mura.waitForExistence(timeout: 10), "[偏 木][旁 寸] の結果に 村 が無い")
        UIPasteboard.general.string = Self.sentinel

        mura.tap()

        XCTAssertTrue(element("copiedBadge", in: app).waitForExistence(timeout: 3), "「コピーしました」が出ない")
        XCTAssertEqual(element("copiedBadge", in: app).label, "「村」をコピーしました")
        XCTAssertEqual(readPasteboard(), "村")
    }

    func testG4_BackToTexteLibreShowsEmptyFreeText() {
        let app = launch()
        selectPosition(0, "偏", app: app)
        selectRadical(0, "木 き", app: app)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'kanji.'")).firstMatch.waitForExistence(timeout: 10))

        selectPosition(0, "texte libre", app: app)

        let field = app.textFields["componentText.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "texte libre に戻しても自由入力欄が出ない")
        XCTAssertFalse(element("componentForm.0", in: app).exists, "texte libre なのに部首のプルダウンがある")
        XCTAssertEqual(field.value as? String, "élément (ex. 木)", "値が空でない")
        XCTAssertTrue(element("emptyHint", in: app).waitForExistence(timeout: 5), "全行が空のヒントに戻らない")
    }

    func testG6_TappingBlankRightOfPositionLabelOpensMenu() {
        let app = launch()
        selectPosition(0, "偏", app: app)
        let picker = app.buttons["componentPosition.0"].firstMatch
        let title = picker.staticTexts["偏"].firstMatch
        let form = app.buttons["componentForm.0"].firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 5))
        // 位置名の文字の右端より右、部首のボタンの左端より左(ラベルの余白)を押す
        let blankMinX = title.frame.maxX
        let blankMaxX = form.frame.minX
        XCTAssertGreaterThan(blankMaxX - blankMinX, 20, "余白が無い")

        for x in [(blankMinX + blankMaxX) / 2, blankMaxX - 3] {
            tap(x: x, y: picker.frame.midY, app: app)

            // 構 はメニューの項目にしか無い(texte libre は 2・3 行目のラベルにもある)
            let kamae = app.buttons["構"].firstMatch
            XCTAssertTrue(kamae.waitForExistence(timeout: 5), "ラベルの右の余白(x=\(x))で位置のメニューが開かない")
            // 次の点を押す前にメニューを閉じる(位置は 偏 のまま。行のラベル 偏 ではなくメニューの項目を押す)
            menuItem("偏", app: app).tap()
            XCTAssertTrue(kamae.waitForNonExistence(timeout: 5), "位置のメニューが閉じない")
        }
    }

    func testG6b_TappingBlankOfRadicalButtonOpensList() {
        let app = launch()
        selectPosition(0, "偏", app: app)
        let form = app.buttons["componentForm.0"].firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 5))
        let placeholder = form.staticTexts["選択"].firstMatch
        // 「選択」の文字の右端と、ボタンの右端の間(文字も矢印も無い所)を押す
        let x = (placeholder.frame.maxX + form.frame.maxX) / 2 - 10

        tap(x: x, y: form.frame.midY, app: app)

        XCTAssertTrue(element("componentFormList.0", in: app).waitForExistence(timeout: 5), "部首のボタンの余白で一覧が開かない")
    }

    func testG7_PositionLabelShowsPositionIcon() {
        let app = launch()

        selectPosition(0, "偏", app: app)

        XCTAssertTrue(element("componentPositionIcon.0.偏", in: app).waitForExistence(timeout: 5), "偏 のアイコンが無い")
    }

    func testG9_TexteLibreHasNoPositionIcon() {
        let app = launch()
        let icons = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'componentPositionIcon.'"))
        XCTAssertTrue(app.buttons["componentPosition.0"].firstMatch.waitForExistence(timeout: 5))

        XCTAssertEqual(icons.count, 0, "texte libre の行にアイコンがある")

        selectPosition(0, "偏", app: app)
        XCTAssertTrue(element("componentPositionIcon.0.偏", in: app).waitForExistence(timeout: 5), "偏 のアイコンが無い")
        XCTAssertEqual(icons.count, 1, "texte libre の行(2・3 行目)にアイコンがある")
    }

    func testG10_FreeTextPlaceholderIsElement() {
        let app = launch()
        let field = app.textFields["componentText.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        XCTAssertEqual(field.placeholderValue, "élément (ex. 木)")
    }

    func testG11_RadicalListSelectsKiAndCloses() {
        let app = launch()
        selectPosition(0, "偏", app: app)

        app.buttons["componentForm.0"].firstMatch.tap()

        let list = element("componentFormList.0", in: app)
        XCTAssertTrue(list.waitForExistence(timeout: 5), "部首の一覧が開かない")
        let ki = app.buttons["componentFormItem.0.木"].firstMatch
        scrollUntilHittable(ki, in: list)
        ki.tap()
        XCTAssertTrue(list.waitForNonExistence(timeout: 5), "選んでも一覧が閉じない")
        XCTAssertTrue(app.buttons["componentForm.0"].firstMatch.label.contains("木 き"), "ボタンに 木 が出ない")
    }

    func testG12_StrokeDividerTakesNoHeight() {
        let app = launch()
        selectPosition(0, "偏", app: app)
        app.buttons["componentForm.0"].firstMatch.tap()
        XCTAssertTrue(element("componentFormList.0", in: app).waitForExistence(timeout: 5), "部首の一覧が開かない")
        // 亻 冫 は 2画、口 土 は 3画(冫 と 口 の間に区切りがある)
        let frames = ["亻", "冫", "口", "土"].map { app.buttons["componentFormItem.0.\($0)"].firstMatch.frame }
        XCTAssertTrue(element("componentFormStroke.0.3", in: app).exists, "3画 の区切りが無い")

        XCTAssertEqual(Set(frames.map(\.height)).count, 1, "項目の高さが揃っていない: \(frames)")
        let gapWithinStrokes = frames[1].minY - frames[0].maxY
        let gapAcrossStrokes = frames[2].minY - frames[1].maxY
        XCTAssertEqual(gapAcrossStrokes, gapWithinStrokes, accuracy: 0.5, "区切りで項目の間隔が変わる: \(frames)")
        XCTAssertEqual(frames[3].minY - frames[2].maxY, gapWithinStrokes, accuracy: 0.5)
        // 画数は線(口 の上端)の下に書く
        let label = element("componentFormStroke.0.3", in: app).frame
        XCTAssertGreaterThanOrEqual(label.minY, frames[2].minY, "3画 が線の上にはみ出している: \(label) / \(frames[2])")
        XCTAssertLessThan(label.maxY, frames[2].midY, "3画 が 口 の上端の近くに無い: \(label) / \(frames[2])")
    }

    func testG13_AucunAtTopClearsRadical() {
        let app = launch()
        selectPosition(0, "偏", app: app)
        selectRadical(0, "木 き", app: app)
        XCTAssertTrue(kanji("村", app: app).waitForExistence(timeout: 5), "偏 木 で 村 が出ない")

        app.buttons["componentForm.0"].firstMatch.tap()
        let list = element("componentFormList.0", in: app)
        XCTAssertTrue(list.waitForExistence(timeout: 5), "部首の一覧が開かない")
        let none = app.buttons["componentFormNone.0"].firstMatch
        XCTAssertTrue(none.waitForExistence(timeout: 5), "Aucun が無い")
        XCTAssertEqual(none.label, "Aucun")
        // 一覧の先頭(部首の最初の項目より上)
        let first = list.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'componentFormItem.0.'")).firstMatch
        XCTAssertLessThan(none.frame.maxY, first.frame.minY + 0.5, "Aucun が先頭に無い")

        none.tap()
        XCTAssertTrue(list.waitForNonExistence(timeout: 5), "Aucun で一覧が閉じない")
        XCTAssertEqual(app.buttons["componentForm.0"].firstMatch.label, "選択", "未選択の表示に戻らない")
        XCTAssertTrue(element("emptyHint", in: app).waitForExistence(timeout: 5), "全行が空のヒントに戻らない")
        XCTAssertFalse(kanji("村", app: app).exists, "前の結果が残っている")
    }

    func testG14_RadicalListOpensOnTouchDown() {
        let app = launch()
        selectPosition(0, "偏", app: app)
        let button = app.buttons["componentForm.0"].firstMatch
        let far = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))

        // 押したまま遠くへ動かしてから離す。離した所はボタンの外なので、Button の action では開かない
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.6, thenDragTo: far)

        XCTAssertTrue(element("componentFormList.0", in: app).waitForExistence(timeout: 5), "触れただけでは部首の一覧が開かない")
    }

    func testG15_KeyboardDoneClosesKeyboardOnFreeText() {
        let app = launch()
        let field = app.textFields["componentText.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "キーボードが出ない")

        app.buttons["keyboardDone"].firstMatch.tap()

        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "完了 でキーボードが閉じない")
    }

    // キーボードが出ても入力欄のフォーカスが外れない(画面の残りの高さが幅を下回っても横向きの配置に切り替えない)
    func testG18_KeyboardStaysAfterFocusingFreeText() {
        let app = launch()
        let field = app.textFields["componentText.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "キーボードが出ない")

        Thread.sleep(forTimeInterval: 2)

        XCTAssertTrue(app.keyboards.firstMatch.exists, "キーボードがすぐ引っ込む")
        field.typeText("木")
        XCTAssertTrue(kanji("村", app: app).waitForExistence(timeout: 10), "入力が欄に入らない")
    }

    func testG16_TappingResultsAreaClosesKeyboard() {
        let app = launch()
        let field = app.textFields["componentText.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "キーボードが出ない")

        element("emptyHint", in: app).tap()

        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "結果の側のタップでキーボードが閉じない")
    }

    func testG17_KeyboardDoneClosesKeyboardOnReading() {
        let app = launch()
        app.tabBars.buttons["japonaise"].tap()
        let field = app.textFields["readingField.kun"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "キーボードが出ない")

        app.buttons["keyboardDone"].firstMatch.tap()

        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "完了 でキーボードが閉じない")
    }

    func testE3_LongPressShowsDetailWithoutCopying() {
        let app = launch()
        UIPasteboard.general.string = Self.sentinel
        selectPosition(0, "偏", app: app)
        selectRadical(0, "木 き", app: app)
        selectPosition(1, "旁", app: app)
        selectRadical(1, "寸 すん", app: app)
        let mura = kanji("村", app: app)
        XCTAssertTrue(mura.waitForExistence(timeout: 10))

        mura.press(forDuration: 1.0)

        XCTAssertTrue(element("detail.on", in: app).waitForExistence(timeout: 5), "詳細が出ない")
        XCTAssertEqual(element("detail.on", in: app).label, "ソン")
        XCTAssertEqual(element("detail.kun", in: app).label, "むら")
        XCTAssertEqual(element("detail.codePoint", in: app).label, "U+6751")
        XCTAssertEqual(element("detail.kuten", in: app).label, "34-28")
        XCTAssertEqual(element("detail.category", in: app).label, "常用 ○  教育 ○(1年)  人名用 —")
        XCTAssertEqual(element("detail.jlpt", in: app).label, "N2(非公式)")
        XCTAssertFalse(element("copiedBadge", in: app).exists, "長押しでコピーされた")
        XCTAssertEqual(readPasteboard(), Self.sentinel)
    }

    func testE3b_DetailSeparatesReadingsWithIdeographicComma() {
        let app = launch()
        app.tabBars.buttons["chinoise"].tap()
        let field = app.textFields["readingField.on"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("ぞん")
        dismissKeyboard(app: app)
        let son = kanji("存", app: app)
        XCTAssertTrue(son.waitForExistence(timeout: 10), "chinoise ぞん の結果に 存 が無い")
        scrollUntilHittable(son, in: app)

        son.press(forDuration: 1.0)

        XCTAssertTrue(element("detail.on", in: app).waitForExistence(timeout: 5), "詳細が出ない")
        XCTAssertEqual(element("detail.on", in: app).label, "ソン、ゾン、セン")
        XCTAssertEqual(element("detail.kun", in: app).label, "ある、たもつ、ながらえる、ぞんじる")
        XCTAssertEqual(element("detail.category", in: app).label, "常用 ○  教育 ○(6年)  人名用 —")
        XCTAssertEqual(element("detail.jlpt", in: app).label, "N3(非公式)")
    }

    func testE3c_DetailMarksJinmeiyoOnlyKanji() {
        let app = launch()
        app.tabBars.buttons["japonaise"].tap()
        let field = app.textFields["readingField.kun"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("よろず")
        dismissKeyboard(app: app)
        let man = kanji("萬", app: app)
        XCTAssertTrue(man.waitForExistence(timeout: 10), "japonaise よろず の結果に 萬 が無い")
        scrollUntilHittable(man, in: app)

        man.press(forDuration: 1.0)

        XCTAssertTrue(element("detail.category", in: app).waitForExistence(timeout: 5), "詳細が出ない")
        XCTAssertEqual(element("detail.category", in: app).label, "常用 ×  教育 ×  人名用 ○")
        XCTAssertEqual(element("detail.jlpt", in: app).label, "—")
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

    func testE6_LicensesShowVersionUnicodeAndBabelStone() {
        let app = launch()

        app.buttons["licensesButton"].firstMatch.tap()

        XCTAssertTrue(element("licensesView", in: app).waitForExistence(timeout: 5), "ライセンス画面が出ない")
        // バージョンとビルド番号は上げるたびに変わるので、値ではなく形で見る
        let version = app.staticTexts["appVersion"]
        XCTAssertTrue(version.waitForExistence(timeout: 5), "バージョンの表示が無い")
        XCTAssertNotNil(
            version.label.range(of: #"^バージョン \d+(\.\d+)*\(ビルド \d+\)$"#, options: .regularExpression),
            "バージョンの表示の形が違う: \(version.label)"
        )
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
        selectPosition(0, "偏", app: app)
        selectRadical(0, "木 き", app: app)
        selectPosition(1, "旁", app: app)
        selectRadical(1, "寸 すん", app: app)
        let form = app.buttons["componentForm.1"].firstMatch
        let first = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'kanji.'")).firstMatch

        XCTAssertTrue(first.waitForExistence(timeout: 10), "結果が出ない")
        XCTAssertTrue(form.isHittable, "横向きで部首のプルダウンが押せない")
        XCTAssertTrue(first.isHittable, "横向きで結果の 1 字目が押せない")
    }

    func testG8a_PositionMenuOpensWhileTypingFreeText() {
        let app = launch()
        let field = app.textFields["componentText.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("木")
        XCTAssertTrue(app.keyboards.firstMatch.exists, "キーボードが出ていない")

        selectPosition(0, "偏", app: app)

        let form = app.buttons["componentForm.0"].firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 5), "入力中に 偏 を選べない")
        XCTAssertTrue(form.label.contains("選択"), "位置を変えても値が空に戻らない: \(form.label)")
    }

    func testG8b_PositionMenuOpensAfterFreeTextIsEntered() {
        let app = launch()
        let field = app.textFields["componentText.0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("木")
        dismissKeyboard(app: app)
        XCTAssertTrue(kanji("木", app: app).waitForExistence(timeout: 10), "texte libre 木 の結果が出ない")

        selectPosition(0, "偏", app: app)

        let form = app.buttons["componentForm.0"].firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 5), "入力済みの行で 偏 を選べない")
        XCTAssertTrue(form.label.contains("選択"), "位置を変えても値が空に戻らない: \(form.label)")
        XCTAssertTrue(element("emptyHint", in: app).waitForExistence(timeout: 5), "全行が空のヒントに戻らない")
        XCTAssertFalse(kanji("木", app: app).exists, "前の結果が残っている")
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

    private func selectPosition(_ index: Int, _ position: String, app: XCUIApplication) {
        let picker = app.buttons["componentPosition.\(index)"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "\(index) 行目の位置が無い")
        picker.tap()
        let item = menuItem(position, app: app)
        XCTAssertTrue(item.waitForExistence(timeout: 5), "位置のメニューに \(position) が無い")
        item.tap()
    }

    // 部首の一覧の項目はラベル(「木 き」)で探す
    private func selectRadical(_ index: Int, _ label: String, app: XCUIApplication) {
        let button = app.buttons["componentForm.\(index)"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(index) 行目の部首のボタンが無い")
        button.tap()
        let list = element("componentFormList.\(index)", in: app)
        XCTAssertTrue(list.waitForExistence(timeout: 5), "部首の一覧が開かない")
        let item = list.buttons[label].firstMatch
        scrollUntilHittable(item, in: list)
        item.tap()
        XCTAssertTrue(list.waitForNonExistence(timeout: 5), "選んでも一覧が閉じない")
        XCTAssertTrue(button.label.contains(label), "\(index) 行目の表示が \(label) にならない: \(button.label)")
    }

    // 位置のメニューの項目。行のラベル(componentPosition.<行>)にも同じ名前があるので、それを除いて探す
    private func menuItem(_ position: String, app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ AND NOT (identifier BEGINSWITH 'componentPosition')", position)).firstMatch
    }

    // 画面の座標(ポイント)を押す
    private func tap(x: CGFloat, y: CGFloat, app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
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
        scrollUntilHittable(target, in: app.scrollViews.firstMatch)
    }

    // 項目が容器の中に収まるまで少しずつ動かす。swipe は行き過ぎて項目が上端に掛かり、
    // 掛かった項目の isHittable は例外になるため、位置を見て上下に 120pt ずつ引く
    private func scrollUntilHittable(_ target: XCUIElement, in container: XCUIElement) {
        for _ in 0..<40 {
            let frame = container.frame
            if target.exists, !target.frame.isEmpty, frame.contains(target.frame), target.isHittable {
                return
            }
            let center = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let pullDown = target.exists && !target.frame.isEmpty && target.frame.minY < frame.minY
            center.press(forDuration: 0.05, thenDragTo: center.withOffset(CGVector(dx: 0, dy: pullDown ? 120 : -120)))
        }
        XCTFail("\(target) が画面に出ない")
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
