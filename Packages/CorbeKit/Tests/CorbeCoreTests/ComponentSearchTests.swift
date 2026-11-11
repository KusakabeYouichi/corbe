import Foundation
import Testing
@testable import CorbeCore

// c01-tests.md の B(生成済みの索引・同値類を読む実データの検索)
@Suite("ComponentSearch(実データ)")
struct ComponentSearchTests {
    @Test("B1 [偏 木][旁 寸] と [texte libre 木][texte libre 寸] は 村 を含む")
    func muraByHenAndTsukuri() {
        #expect(Bundled.characters((.hen, "木"), (.tsukuri, "寸")).contains("村"))
        #expect(Bundled.characters((.unspecified, "木"), (.unspecified, "寸")).contains("村"))
    }

    @Test("B2 水 は位置で 河(偏)と 泉(脚)を分ける")
    func waterIsDistinguishedByPosition() {
        let hen = Bundled.characters((.hen, "水"))
        let ashi = Bundled.characters((.ashi, "水"))
        let any = Bundled.characters((.unspecified, "水"))

        #expect(hen.contains("河"))
        #expect(!hen.contains("泉"))
        #expect(ashi.contains("泉"))
        #expect(!ashi.contains("河"))
        #expect(any.contains("河"))
        #expect(any.contains("泉"))
    }

    @Test("B3 異体の形 氵 は代表字 水 に広げない")
    func variantIsNotWidenedToRepresentative() {
        let any = Bundled.characters((.unspecified, "氵"))

        #expect(Bundled.characters((.hen, "氵")).contains("河"))
        #expect(any.contains("河"))
        #expect(!any.contains("泉"))
    }

    @Test("B4 阝 は 旁 なら 郡、偏 なら 阪")
    func kozatoAndOozatoAreDistinguishedByPosition() {
        let tsukuri = Bundled.characters((.tsukuri, "阝"))
        let hen = Bundled.characters((.hen, "阝"))
        let any = Bundled.characters((.unspecified, "阝"))

        #expect(tsukuri.contains("郡"))
        #expect(!tsukuri.contains("阪"))
        #expect(hen.contains("阪"))
        #expect(!hen.contains("郡"))
        #expect(any.contains("郡"))
        #expect(any.contains("阪"))
    }

    @Test("B5 花 は 冠 艹 / 冠 艸 で当たり、亻 は脚の中なので 偏 では当たらない")
    func hanaByKanmuri() {
        #expect(Bundled.characters((.kanmuri, "艹")).contains("花"))
        #expect(Bundled.characters((.kanmuri, "艸")).contains("花"))
        #expect(!Bundled.characters((.hen, "亻")).contains("花"))
        #expect(Bundled.characters((.unspecified, "亻")).contains("花"))
    }

    @Test("B6 繞 辶 → 進、垂 疒 → 病、構 門 → 閑、構 囗 → 国")
    func enclosingPositions() {
        #expect(Bundled.characters((.nyou, "辶")).contains("進"))
        #expect(Bundled.characters((.tare, "疒")).contains("病"))
        #expect(Bundled.characters((.kamae, "門")).contains("閑"))
        #expect(Bundled.characters((.kamae, "囗")).contains("国"))
    }

    @Test("B7 texte libre 可 は 河 に当たり 司 に当たらない。texte libre 寺 は 封 に当たらない")
    func unspecifiedDoesNotMatchLookalikes() {
        let ka = Bundled.characters((.unspecified, "可"))

        #expect(ka.contains("河"))
        #expect(!ka.contains("司"))
        #expect(!Bundled.characters((.unspecified, "寺")).contains("封"))
    }

    @Test("B8 旁 月 は 湖 の旁の子孫(胡 の 月)に当たり、偏 月 は当たらない")
    func descendantsInheritPosition() {
        #expect(Bundled.characters((.tsukuri, "月")).contains("湖"))
        #expect(!Bundled.characters((.hen, "月")).contains("湖"))
    }

    @Test("B9 偏 言 は 謝(訁)に当たる")
    func gonbenFromSupplementTable() {
        #expect(Bundled.characters((.hen, "言")).contains("謝"))
    }

    @Test("B10 偏 木 と 旁 木 の 2 行で 林 に当たる")
    func sameComponentInTwoPositions() {
        #expect(Bundled.characters((.hen, "木"), (.tsukuri, "木")).contains("林"))
    }

    @Test("B11 3 行すべて空なら 0 件で、空の問い合わせとして返す")
    func allRowsEmpty() {
        let result = Bundled.componentSearch.search([ComponentQueryRow(), ComponentQueryRow(), ComponentQueryRow()])

        #expect(result.entries.isEmpty)
        #expect(result.isEmptyQuery)
    }

    @Test("B12 漢字でない部品(a・あ)の行は使えない印が付き、0 件")
    func nonHanComponentIsUnusable() {
        for text in ["a", "あ"] {
            let result = Bundled.componentSearch.search([
                ComponentQueryRow(position: .hen, text: "木"),
                ComponentQueryRow(position: .unspecified, text: text)
            ])

            #expect(result.rows == [.components(["木"]), .unusable], "\(text)")
            #expect(result.entries.isEmpty, "\(text)")
        }
    }

    @Test("B13 1 行に 木寸 と入れると 木 と 寸 の 2 行と同じ結果")
    func oneRowWithTwoComponents() {
        let combined = Bundled.characters((.unspecified, "木寸"))

        #expect(combined == Bundled.characters((.unspecified, "木"), (.unspecified, "寸")))
        #expect(combined.contains("村"))
    }

    @Test("B14 ⺡(CJK Radicals Supplement)は 氵、⼈(Kangxi Radical)は 人 と同じ結果")
    func radicalCharactersAreMapped() {
        let supplement = Bundled.characters((.hen, "\u{2EA1}"))
        let kangxi = Bundled.characters((.unspecified, "\u{2F08}"))

        #expect(supplement.contains("河"))
        #expect(supplement == Bundled.characters((.hen, "氵")))
        #expect(kangxi.contains("人"))
        #expect(kangxi == Bundled.characters((.unspecified, "人")))
    }

    @Test("B15 texte libre 木 は 木 自身を含み、偏 木 は含まない")
    func characterItselfMatchesOnlyUnspecified() {
        #expect(Bundled.characters((.unspecified, "木")).contains("木"))
        #expect(!Bundled.characters((.hen, "木")).contains("木"))
    }

    @Test("B16 結果は 総画数 → コードポイント 順([偏 木][旁 寸] の全件)")
    func resultsAreOrderedByTotalStrokesThenCodePoint() {
        #expect(Bundled.characters((.hen, "木"), (.tsukuri, "寸")) == [
            "村", "柎", "树", "桪", "梼", "棏", "椨", "榑", "榭", "榯", "槈",
            "槫", "樳", "樹", "樽", "橱", "檮", "檲", "櫉", "櫥", "欂"
        ])
    }

    @Test("B17 同値類の異体の形(水 言 艸 辵 人 糸)")
    func variantClassesAreFixed() {
        #expect(Bundled.variants.radicalClass(forRadical: 85)?.variants == ["氵", "氺"])
        #expect(Bundled.variants.radicalClass(forRadical: 149)?.variants == ["讠", "訁"])
        #expect(Bundled.variants.radicalClass(forRadical: 140)?.variants == ["艹"])
        #expect(Bundled.variants.radicalClass(forRadical: 162)?.variants == ["辶"])
        #expect(Bundled.variants.radicalClass(forRadical: 9)?.variants == ["亻", "𠆢"])
        #expect(Bundled.variants.radicalClass(forRadical: 120)?.variants == ["纟", "糹"])
    }

    @Test("B18 原子部品は筆画まで分解しないので、人 一 十 囗 は 村 林 進 明 に当たらない")
    func atomicCutoffPreventsFalseMatches() {
        let anyPerson = Bundled.characters((.unspecified, "人"))

        #expect(!Bundled.characters((.hen, "人")).contains("村"))
        #expect(!anyPerson.contains("林"))
        #expect(!anyPerson.contains("進"))
        #expect(!Bundled.characters((.hen, "一")).contains("村"))
        #expect(!Bundled.characters((.unspecified, "十")).contains("村"))
        #expect(!Bundled.characters((.hen, "囗")).contains("明"))
    }

    @Test("B19 CJK Strokes の ㇉ は使えない印が付き、0 件")
    func cjkStrokeIsUnusable() {
        let result = Bundled.componentSearch.search([ComponentQueryRow(position: .unspecified, text: "㇉")])

        #expect(result.rows == [.unusable])
        #expect(result.entries.isEmpty)
    }

    @Test("B20 IDS の ⺝ はビルド時に 月 へ寄せるので [脚 月] は 育 に当たり、Supplement の字は ⺀ ⺈ だけが部品に残る")
    func supplementComponentsAreFoldedAtBuildTime() {
        let remaining = Set(Bundled.index.entries.flatMap { entry in
            entry.components.map(\.component).filter { component in
                component.unicodeScalars.contains { (0x2E80...0x2EFF).contains($0.value) }
            }
        })

        #expect(Bundled.characters((.ashi, "月")).contains("育"))
        // ⺀(CJK RADICAL REPEAT)は EquivalentUnifiedIdeograph に対応が無いので残る。
        // ⺈(ク の形)は読み替え表で探すため寄せずに残す。⺍ も寄せないが、選んだ IDS には現れない(ツ の形は 𭕄 で書かれる)
        #expect(remaining == ["⺀", "⺈"])
    }

    @Test("B21 𤣩 はビルド時に 王 へ寄せるので [偏 王] と [偏 玉] は 球 に当たる")
    func tamahenIsFoldedToOu() {
        #expect(Bundled.characters((.hen, "王")).contains("球"))
        #expect(Bundled.characters((.hen, "玉")).contains("球"))
    }

    @Test("H1 texte libre の片仮名 マ ナ ツ ク は、その形の部品を持つ字に当たる")
    func katakanaShapesFindComponents() {
        #expect(Set(Bundled.characters((.unspecified, "マ"))).isSuperset(of: ["予", "勇", "通"]))
        #expect(Set(Bundled.characters((.unspecified, "ナ"))).isSuperset(of: ["左", "右", "有"]))
        #expect(Set(Bundled.characters((.unspecified, "ツ"))).isSuperset(of: ["単", "巣", "労", "学"]))
        #expect(Set(Bundled.characters((.unspecified, "ク"))).isSuperset(of: ["負", "争", "急"]))
    }

    @Test("H2 texte libre 尚 は 龸 𫩠 と書かれた 常 賞 堂 掌 にも、尚 そのものを持つ字にも当たる")
    func shouFindsVariantShapes() {
        let shou = Set(Bundled.characters((.unspecified, "尚")))

        #expect(shou.isSuperset(of: ["常", "賞", "堂", "掌"]))
        #expect(shou.isSuperset(of: ["躺", "緔"]))
    }

    @Test("H3 ひらがな ま は使えない部品で、半角カタカナの ク(U+FF78)は 全角 ク と同じ結果")
    func hiraganaIsUnusableAndHalfwidthIsNormalized() {
        let hiragana = Bundled.componentSearch.search([ComponentQueryRow(position: .unspecified, text: "ま")])
        let halfwidth = Bundled.characters((.unspecified, "\u{FF78}"))

        #expect(hiragana.rows == [.unusable])
        #expect(hiragana.entries.isEmpty)
        #expect(halfwidth.contains("負"))
        #expect(halfwidth == Bundled.characters((.unspecified, "ク")))
    }

    @Test("H4 1 行に マ力 と入れると AND で、勇 に当たり 予 に当たらない")
    func aliasIsAndedWithOtherCharacters() {
        let result = Bundled.characters((.unspecified, "マ力"))

        #expect(result.contains("勇"))
        #expect(!result.contains("予"))
    }

    @Test("H5 入力した ⺈ は 刀 へ寄せず ⺈ で照合するので、負 争 急 に当たり 刀 そのものには当たらない")
    func typedKuShapeMatchesItself() {
        let typed = Bundled.characters((.unspecified, "\u{2E88}"))

        #expect(Set(typed).isSuperset(of: ["負", "争", "急"]))
        #expect(!typed.contains("刀"))
    }

    @Test("H5 ⺈ は 刀 へ寄せないので [冠 刀] は 負 に当たらない")
    func kuShapeIsNotFoldedToKatana() {
        #expect(!Bundled.characters((.kanmuri, "刀")).contains("負"))
    }
}

// 照合の規則を小さな合成データで確かめる
@Suite("ComponentSearch(規則)")
struct ComponentSearchRuleTests {
    @Test("読み替え表の照合する部品に漢字でない字(かな)があれば、その行を読み込みエラーにする")
    func aliasTargetMustBeHanComponent() {
        #expect(throws: CorbeDataError.malformedLine(file: "ComponentInputAliases.tsv", line: 2)) {
            try ComponentInputParser(contents: "", aliasContents: "マ\t龴\nク\tく")
        }
    }

    // 甲 = 偏 水 / 乙 = 偏 氵 / 丙 = 脚 水 / 丁 = 分解なし
    private static let search = ComponentSearch(
        index: KanjiIndex(entries: [
            entry("甲", total: 5, components: [ComponentToken(slot: .hen, component: "水")]),
            entry("乙", total: 1, components: [ComponentToken(slot: .hen, component: "氵")]),
            entry("丙", total: 5, components: [ComponentToken(slot: .ashi, component: "水")]),
            entry("丁", total: 2, components: [])
        ]),
        variants: ComponentVariants(classes: [
            .init(radical: 85, representative: "水", variants: ["氵", "氺"])
        ]),
        parser: ComponentInputParser(supplementEquivalents: ["\u{2EA1}": "氵"])
    )

    private static func entry(_ character: String, total: Int, components: [ComponentToken]) -> KanjiEntry {
        KanjiEntry(
            character: character,
            radical: 1,
            residualStrokes: 0,
            totalStrokes: total,
            kuten: "",
            onReadings: [],
            kunReadings: [],
            components: components
        )
    }

    private static func characters(_ rows: [ComponentQueryRow]) -> [String] {
        search.search(rows).entries.map(\.character)
    }

    @Test("代表字は異体の形にも当たり、結果は総画数 → コードポイント順")
    func representativeExpandsToVariants() {
        #expect(Self.characters([ComponentQueryRow(position: .hen, text: "水")]) == ["乙", "甲"])
    }

    @Test("異体の形は自分だけに当たる")
    func variantMatchesOnlyItself() {
        #expect(Self.characters([ComponentQueryRow(position: .unspecified, text: "氵")]) == ["乙"])
    }

    @Test("位置の指定はその位置の部品だけに当たる")
    func positionRestrictsSlot() {
        #expect(Self.characters([ComponentQueryRow(position: .ashi, text: "水")]) == ["丙"])
    }

    @Test("分解の無い字は texte libre で自分自身に一致するときだけ出る")
    func undecomposedCharacterMatchesItself() {
        #expect(Self.characters([ComponentQueryRow(position: .unspecified, text: "丁")]) == ["丁"])
        #expect(Self.characters([ComponentQueryRow(position: .hen, text: "丁")]) == [])
    }

    @Test("行は AND で、空の行は無視する")
    func rowsAreCombinedWithAnd() {
        #expect(Self.characters([
            ComponentQueryRow(position: .unspecified, text: "水"),
            ComponentQueryRow(position: .hen, text: " "),
            ComponentQueryRow(position: .hen, text: "氵")
        ]) == ["乙"])
    }

    @Test("部品テキストは NFKC にして空白を除き、CJK Radicals Supplement を対応表で移す")
    func parserNormalizesInput() {
        let parser = ComponentInputParser(supplementEquivalents: ["\u{2EA1}": "氵"])

        #expect(parser.parse(" \u{2F08} \u{2EA1}\u{3000}木 ") == .components(["人", "氵", "木"]))
        #expect(parser.parse("　 ") == .empty)
        #expect(parser.parse("木\u{FF21}") == .unusable)
        #expect(parser.parse("ア") == .unusable)
    }
}
