import Foundation
import Testing
@testable import CorbeCore

// c02-tests.md の F(corbé タブの位置ごとの部首プルダウンの選択肢。期待値は実データで一度数えた固定値)
@Suite("ComponentPositionChoices(実データ)")
struct ComponentPositionChoicesTests {
    private static let radicalPositions: [ComponentPosition] = [.hen, .tsukuri, .kanmuri, .ashi, .tare, .nyou, .kamae]

    private func labels(_ position: ComponentPosition) -> [String] {
        Bundled.positionChoices.choices(for: position).map(\.label)
    }

    private func choice(_ position: ComponentPosition, radical: Int) throws -> ComponentRadicalChoice {
        try #require(Bundled.positionChoices.choices(for: position).first { $0.radical == radical })
    }

    // 項目を選んだときと同じ行(位置, 照合する字)で検索する
    private func characters(_ position: ComponentPosition, radical: Int) throws -> [String] {
        Bundled.characters((position, try choice(position, radical: radical).query))
    }

    @Test("F1 位置の 1 番目の表示は texte libre で、並びは texte libre 偏 旁 冠 脚 垂 繞 構")
    func positionTitles() {
        #expect(ComponentPosition.unspecified.title == "texte libre")
        #expect(ComponentPosition.allCases.map(\.title) == ["texte libre", "偏", "旁", "冠", "脚", "垂", "繞", "構"])
    }

    @Test("F1 texte libre には部首の選択肢が無い")
    func texteLibreHasNoChoices() {
        #expect(Bundled.positionChoices.sections(for: .unspecified).isEmpty)
    }

    @Test("F2 偏 の選択肢は 2画 の 亻 冫、3画 の 口 土 夕 … と始まり、亻 氵 木 言 を含む")
    func henChoicesStartWithTwoStrokes() throws {
        let sections = Bundled.positionChoices.sections(for: .hen)

        #expect(sections.prefix(2).map(\.strokes) == [2, 3])
        #expect(sections[0].choices.map(\.label) == ["亻 にんべん", "冫 にすい"])
        #expect(sections[1].choices.prefix(4).map(\.label) == ["口 くち", "土 つち", "夕 ゆうべ", "女 おんな"])
        let forms = Set(Bundled.positionChoices.choices(for: .hen).flatMap(\.forms))
        #expect(forms.isSuperset(of: ["亻", "氵", "木", "言"]))
    }

    @Test("F3 繞 の選択肢は 廴 えんにょう / 辶 辵 しんにょう / 走 そうにょう の 3 項目")
    func nyouChoices() {
        let choices = Bundled.positionChoices.choices(for: .nyou)

        #expect(choices.map(\.label) == ["廴 えんにょう", "辶 辵 しんにょう", "走 そうにょう"])
        #expect(choices.map(\.radical) == [54, 162, 156])
        #expect(choices.map(\.query) == ["廴", "辵", "走"])
    }

    @Test("F3 垂 の選択肢は 疒 广 厂 尸 を含む")
    func tareChoicesContainCommonForms() {
        let forms = Set(Bundled.positionChoices.choices(for: .tare).flatMap(\.forms))

        #expect(forms.isSuperset(of: ["疒", "广", "厂", "尸"]))
    }

    @Test("F3b どの位置でも部首番号の重複した項目は無い")
    func noDuplicateRadicalInAnyPosition() {
        for position in Self.radicalPositions {
            let radicals = Bundled.positionChoices.choices(for: position).map(\.radical)

            #expect(Set(radicals).count == radicals.count, "\(position.title)")
        }
    }

    @Test("F3b 脚 の 心 と ⺗ は 1 項目「⺗ 心 したごころ・こころ」で、照合は 心")
    func ashiMergesKokoroForms() throws {
        let kokoro = try choice(.ashi, radical: 61)

        #expect(kokoro.label == "⺗ 心 したごころ・こころ")
        #expect(kokoro.strokes == 4)
        #expect(kokoro.query == "心")
    }

    @Test("F3b 偏 の 阝 阜 は最小の画数 3 の見出しに入る")
    func mergedItemUsesMinimumStrokes() throws {
        let kozato = try choice(.hen, radical: 170)

        #expect(kozato.label == "阝 阜 こざとへん・おか")
        #expect(kozato.strokes == 3)
        #expect(kozato.query == "阜")
    }

    @Test("F4 画数の見出しは昇順で、見出しの中は同じ画数の項目が部首番号の昇順に並ぶ(全位置)")
    func choicesAreOrderedByStrokesThenRadical() {
        for position in Self.radicalPositions {
            let sections = Bundled.positionChoices.sections(for: position)
            let strokes = sections.map(\.strokes)

            #expect(strokes == strokes.sorted() && Set(strokes).count == strokes.count, "\(position.title)")
            for section in sections {
                let radicals = section.choices.map(\.radical)
                #expect(section.choices.allSatisfy { $0.strokes == section.strokes }, "\(position.title) \(section.strokes)")
                #expect(radicals == radicals.sorted(), "\(position.title) \(section.strokes)")
            }
        }
    }

    @Test("F4 垂 の見出しは 2 3 4 5 6 11 画")
    func tareSectionHeaders() {
        #expect(Bundled.positionChoices.sections(for: .tare).map(\.strokes) == [2, 3, 4, 5, 6, 11])
        #expect(Bundled.positionChoices.sections(for: .tare).last?.choices.map(\.label) == ["鹿 しか", "麻 あさ"])
    }

    @Test("F5 すべての項目は、その位置 1 行だけで検索すると 1 字以上当たる(全位置・全項目)")
    func everyChoiceHasResults() {
        for position in Self.radicalPositions {
            for choice in Bundled.positionChoices.choices(for: position) {
                #expect(!Bundled.characters((position, choice.query)).isEmpty, "\(position.title) \(choice.label)")
            }
        }
    }

    @Test("F5 その位置で 1 字以上当たる部首は必ず選択肢にある(全位置・bushu.plist の全部首)")
    func everyRadicalWithResultsIsOffered() {
        let positions: [(ComponentPosition, RadicalPositionCategory)] = [
            (.hen, .hen), (.tsukuri, .tsukuri), (.kanmuri, .kanmuri), (.ashi, .ashi),
            (.tare, .tare), (.nyou, .nyou), (.kamae, .kamae)
        ]
        for (position, category) in positions {
            let offered = Set(Bundled.positionChoices.choices(for: position).map(\.radical))
            let radicals = Set(Bundled.catalog.forms(in: category).map(\.radical))
            for radical in radicals.sorted() {
                // 照合する字は仕様から: 部首の代表字、130(肉)だけは 月。
                // 実装の query がこの規則どおりであることは F3・F3b・F6 の固定値が守っている(ここは除外の漏れだけを見る)
                let query = radical == 130 ? "月" : (Bundled.variants.radicalClass(forRadical: radical)?.representative ?? "")
                if !Bundled.characters((position, query)).isEmpty {
                    #expect(offered.contains(radical), "\(position.title) 部首 \(radical)")
                }
            }
        }
    }

    @Test("F5 0 件の字形は除く: 偏 の 尢、旁 の 彐、構 の 行 は bushu.plist にあるが選択肢に無い")
    func zeroHitFormsAreRemoved() {
        let catalog = Bundled.catalog

        #expect(catalog.forms(in: .hen).contains { $0.form == "尢" })
        #expect(Bundled.characters((.hen, "尢")).isEmpty)
        #expect(!Bundled.positionChoices.choices(for: .hen).contains { $0.radical == 43 })
        #expect(catalog.forms(in: .tsukuri).contains { $0.form == "彐" })
        #expect(!Bundled.positionChoices.choices(for: .tsukuri).contains { $0.radical == 58 })
        #expect(catalog.forms(in: .kamae).contains { $0.form == "行" })
        #expect(!Bundled.positionChoices.choices(for: .kamae).contains { $0.radical == 144 })
    }

    @Test("F5 項目の数は 偏 89 旁 53 冠 37 脚 60 垂 8 繞 3 構 10")
    func choiceCounts() {
        #expect(Self.radicalPositions.map { Bundled.positionChoices.choices(for: $0).count } == [89, 53, 37, 60, 8, 3, 10])
    }

    @Test("F6 構 門 → 閑、垂 疒 → 病、冠 くさかんむり → 花、繞 しんにょう → 進")
    func choiceFindsTypicalCharacters() throws {
        #expect(try characters(.kamae, radical: 169).contains("閑"))
        #expect(try characters(.tare, radical: 104).contains("病"))
        #expect(try characters(.kanmuri, radical: 140).contains("花"))
        #expect(try characters(.nyou, radical: 162).contains("進"))
    }

    @Test("F6 偏 にくづき は 月 で照合して 肝 を含む")
    func nikuzukiMatchesByTsuki() throws {
        let nikuzuki = try choice(.hen, radical: 130)

        #expect(nikuzuki.label == "⺼ にくづき")
        #expect(nikuzuki.query == "月")
        #expect(try characters(.hen, radical: 130).contains("肝"))
    }

    @Test("F6 偏 さんずい は 河 を含み 泉 を含まない")
    func sanzuiFindsKawaNotIzumi() throws {
        let sanzui = try characters(.hen, radical: 85)

        #expect(sanzui.contains("河"))
        #expect(!sanzui.contains("泉"))
    }
}
