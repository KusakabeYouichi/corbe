import Foundation
import Testing
@testable import CorbeCore

// c01-tests.md の D(Kangxi: bushu.plist の部首一覧と、部首の字グリッド)
@Suite("RadicalCatalog")
struct RadicalCatalogTests {
    // 一覧の項目を "#2"(画数の区切り)と字形の文字列にする
    private func labels(_ items: [(id: String, kind: RadicalListItem)]) -> [String] {
        items.map { item in
            switch item.kind {
            case .strokeMarker(let strokes): return "#\(strokes)"
            case .form(let form): return form.displayForm
            }
        }
    }

    private func labels(_ items: [(id: String, kind: KanjiListItem)]) -> [String] {
        items.map { item in
            switch item.kind {
            case .totalStrokeMarker(let total): return "#\(total)"
            case .character(let entry): return entry.character
            }
        }
    }

    @Test("D1 偏 の部首一覧は 画数 → 部首番号 順で、画数が変わる位置に区切りが入る")
    func henListIsOrderedByStrokesWithMarkers() {
        let items = StrokeListing.radicalListItems(forms: Bundled.catalog.forms(in: .hen))

        #expect(labels(items).prefix(9) == ["#2", "亻", "冫", "#3", "口", "土", "夕", "女", "子"])
    }

    @Test("D2 部首 75 の字グリッドは 1,018 字で、索引順に 総画数の区切りを挟んで 木 朩 / 未 末 本 札 朮 と並ぶ")
    func radical75Grid() {
        let entries = Bundled.index.entries(forRadical: 75)
        let items = StrokeListing.characterListItems(entries: entries)

        #expect(entries.count == 1_018)
        #expect(labels(items).prefix(9) == ["#4", "木", "朩", "#5", "未", "末", "本", "札", "朮"])
    }

    @Test("D3 カテゴリーを変えると部首の選択が閉じる")
    @MainActor
    func changingCategoryClosesForm() throws {
        let state = RadicalPickerState()
        let form = try #require(Bundled.catalog.forms(in: .hen).first)
        state.selectForm(form)

        state.selectCategory(.kanmuri)

        #expect(state.selectedCategory == .kanmuri)
        #expect(state.selectedForm == nil)
    }

    @Test("D4 bushu.plist の字形は全部 1〜214 の部首番号を持つ")
    func everyFormHasKangxiRadicalNumber() {
        let outOfRange = Bundled.catalog.allForms.filter { !(1...214).contains($0.radical) }

        #expect(Bundled.catalog.allForms.count == 245)
        #expect(outOfRange.isEmpty)
    }

    @Test("D5 流儀の分かれる 艹 辶 礻 飠 は既定の画数(3, 3, 4, 7)で一覧に並ぶ")
    func splitStrokeFormsUseDefaultStrokes() {
        let cases: [(RadicalPositionCategory, Int, String, Int)] = [
            (.kanmuri, 140, "艹", 3), (.nyou, 162, "辶", 3), (.hen, 113, "礻", 4), (.hen, 184, "飠", 7)
        ]
        for (category, radical, glyph, strokes) in cases {
            let items = StrokeListing.radicalListItems(forms: Bundled.catalog.forms(in: category))
            let position = items.firstIndex { item in
                if case .form(let form) = item.kind {
                    return form.radical == radical && form.form == glyph
                }
                return false
            }
            let marker = position.flatMap { index in
                items[..<index].last { item in
                    if case .strokeMarker = item.kind {
                        return true
                    }
                    return false
                }
            }

            #expect(position != nil, "\(glyph)")
            #expect(marker.map { labels([$0]) } == ["#\(strokes)"], "\(glyph)")
        }
    }

    @Test("字グリッドの区切りは総画数が変わる位置だけに入り、総画数 0 の字には出さない")
    func characterListMarkers() {
        let entries = [("甲", 0), ("乙", 3), ("丙", 3), ("丁", 5)].map { character, total in
            KanjiEntry(
                character: character,
                radical: 1,
                residualStrokes: 0,
                totalStrokes: total,
                kuten: "",
                onReadings: [],
                kunReadings: [],
                components: []
            )
        }

        #expect(labels(StrokeListing.characterListItems(entries: entries)) == ["甲", "#3", "乙", "丙", "#5", "丁"])
    }
}
