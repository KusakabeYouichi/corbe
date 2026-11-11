import XCTest

// E2E のテストとスクリーンショットの撮影で共通の、起動と画面操作
@MainActor
extension XCTestCase {
    // MARK: - 起動

    // arguments: アプリへ渡す起動引数(コピーの表示を延ばす -corbeUITestBadgeSeconds など)
    func launch(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
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

    func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    func kanji(_ character: String, app: XCUIApplication) -> XCUIElement {
        element("kanji.\(character)", in: app)
    }

    func text(containing fragment: String, app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
    }

    func selectPosition(_ index: Int, _ position: String, app: XCUIApplication) {
        let picker = app.buttons["componentPosition.\(index)"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "\(index) 行目の位置が無い")
        picker.tap()
        let item = menuItem(position, app: app)
        XCTAssertTrue(item.waitForExistence(timeout: 5), "位置のメニューに \(position) が無い")
        item.tap()
    }

    // 部首の一覧の項目はラベル(『木 き』)で探す
    func selectRadical(_ index: Int, _ label: String, app: XCUIApplication) {
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
    func menuItem(_ position: String, app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ AND NOT (identifier BEGINSWITH 'componentPosition')", position)).firstMatch
    }

    // 画面の座標(ポイント)を押す
    func tap(x: CGFloat, y: CGFloat, app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
    }

    func dismissKeyboard(app: XCUIApplication) {
        guard app.keyboards.firstMatch.exists else {
            return
        }
        let done = app.keyboards.buttons.matching(NSPredicate(format: "label IN %@", ["完了", "Done", "done", "改行", "Return", "return"])).firstMatch
        if done.exists {
            done.tap()
        }
    }

    func scrollUntilHittable(_ target: XCUIElement, inResultsOf app: XCUIApplication) {
        scrollUntilHittable(target, in: app.scrollViews.firstMatch)
    }

    // 項目が容器の中に収まるまで少しずつ動かす。swipe は行き過ぎて項目が上端に掛かり、
    // 掛かった項目の isHittable は例外になるため、位置を見て上下に 120pt ずつ引く
    func scrollUntilHittable(_ target: XCUIElement, in container: XCUIElement) {
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
}
