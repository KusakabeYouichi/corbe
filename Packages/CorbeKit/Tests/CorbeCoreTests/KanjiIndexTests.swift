import Foundation
import Testing
@testable import CorbeCore

// c01-tests.md の A(生成済み KanjiIndex.tsv を読む。期待値は Unihan 17.0.0 / BabelStone IDS 2025-06-27 の実データ)
@Suite("KanjiIndex")
struct KanjiIndexTests {
    @Test("A1 索引は U+4E00–9FFF の 20,992 字")
    func indexHasAllUnifiedIdeographs() {
        #expect(Bundled.index.entries.count == 20_992)
    }

    @Test("A2 村 は 部首 75・部首内 3 画・総画数 7・区点 34-28・音 ソン・訓 むら・部品は 偏 木 と 旁 寸 だけ")
    func muraEntry() throws {
        let entry = try #require(Bundled.entry("村"))

        #expect(entry.radical == 75)
        #expect(entry.residualStrokes == 3)
        #expect(entry.totalStrokes == 7)
        #expect(entry.kuten == "34-28")
        #expect(entry.onReadings == ["ソン"])
        #expect(entry.kunReadings == ["むら"])
        #expect(Bundled.tokens("村") == ["L:木", "R:寸"])
    }

    @Test("A3 上 の読みは件数で切らない(音 2 件・訓 11 件)")
    func readingsAreNotTruncated() throws {
        let entry = try #require(Bundled.entry("上"))

        #expect(entry.onReadings == ["ジョウ", "ショウ"])
        #expect(entry.kunReadings == [
            "うえ", "うわ", "かみ", "あげる", "あがる", "のぼる", "のぼせる", "のぼす", "たっとぶ", "たてまつる", "ほとり"
        ])
    }

    @Test("A4 丂 は区点・訓が空、音 コウ、部品は 冠 一 だけ(CJK Strokes の ㇉ は捨てる)")
    func strokeComponentsAreDropped() throws {
        let entry = try #require(Bundled.entry("丂"))

        #expect(entry.kuten == "")
        #expect(entry.onReadings == ["コウ"])
        #expect(entry.kunReadings == [])
        #expect(Bundled.tokens("丂") == ["T:一"])
    }

    @Test("A5 全行が 部首 → 総画数 → 部首内画数 → コードポイント の順に並ぶ")
    func indexIsSortedByRadicalThenStrokes() {
        let entries = Bundled.index.entries
        let outOfOrder = zip(entries, entries.dropFirst()).first { lhs, rhs in
            (lhs.radical, lhs.totalStrokes, lhs.residualStrokes, lhs.codePoint)
                >= (rhs.radical, rhs.totalStrokes, rhs.residualStrokes, rhs.codePoint)
        }

        #expect(outOfOrder == nil)
    }

    @Test("A6 区点は区・点とも先頭ゼロなし(丐 48-2、一 16-76)")
    func kutenHasNoLeadingZero() {
        #expect(Bundled.entry("丐")?.kuten == "48-2")
        #expect(Bundled.entry("一")?.kuten == "16-76")
    }

    @Test("A7 花 は J の IDS ⿱艹化 を選び、化 を再帰展開する")
    func hanaExpandsKa() {
        #expect(Bundled.tokens("花") == ["T:艹", "B:化", "B:亻", "B:匕"])
    }

    @Test("A8 最上位が ⿻ の 与 は部品が空、㇯ の 乌 は第 1 項だけ(他 鸟)")
    func overlayAndSubtraction() {
        #expect(Bundled.tokens("与") == [])
        #expect(Bundled.tokens("乌") == ["O:鸟"])
    }

    @Test("A9 巽 は角括弧の無い J の IDS ⿱⿰己己共 を選ぶ")
    func tatsumiSelectsJapaneseSource() {
        let tokens = Bundled.tokens("巽")

        #expect(tokens.contains("T:己"))
        #expect(tokens.contains("B:共"))
        #expect(!tokens.contains("T:巳"))
    }

    @Test("A10 〾 で始まる 七 は空、⿾ の 卐 は 他 卍")
    func variationIndicatorAndMirror() {
        #expect(Bundled.entry("七") != nil)
        #expect(Bundled.tokens("七") == [])
        #expect(Bundled.tokens("卐") == ["O:卍"])
    }

    @Test("A11 原子部品 木 日 寸 隹 は部品が空で、村 は 木 を筆画まで分解しない")
    func atomicComponentsAreNotExpanded() throws {
        for character in ["木", "日", "寸", "隹"] {
            #expect(Bundled.tokens(character) == [], "\(character)")
        }
        let components = Set(try #require(Bundled.entry("村")).components.map(\.component))

        #expect(components.isDisjoint(with: ["十", "𠆢", "一", "丨"]))
    }
}
