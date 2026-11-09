import Foundation
import Testing
@testable import CorbeCore

// c01-tests.md の C(読みの前方一致。生成済みの索引を読む)
@Suite("ReadingSearch")
struct ReadingSearchTests {
    private func characters(_ input: String, _ kind: ReadingKind) -> [String] {
        Bundled.readingSearch.search(input, kind: kind).map(\.character)
    }

    @Test("C1 chinoise は そん・ソン・ｿﾝ で同じ結果になり、村 を含む")
    func onReadingAcceptsHiraganaKatakanaAndHalfwidth() {
        let hiragana = characters("そん", .on)

        #expect(hiragana.contains("村"))
        #expect(characters("ソン", .on) == hiragana)
        #expect(characters("ｿﾝ", .on) == hiragana)
    }

    @Test("C2 chinoise は前方一致(そ で 村)")
    func onReadingIsPrefixMatch() {
        #expect(characters("そ", .on).contains("村"))
    }

    @Test("C3 japonaise は むら・ムラ・む で 村 を含む")
    func kunReadingAcceptsHiraganaAndKatakana() {
        #expect(characters("むら", .kun).contains("村"))
        #expect(characters("ムラ", .kun).contains("村"))
        #expect(characters("む", .kun).contains("村"))
    }

    @Test("C4 音と訓は混ぜない(chinoise むら・japonaise そん は 村 を含まない)")
    func onAndKunAreSeparate() {
        #expect(!characters("むら", .on).contains("村"))
        #expect(!characters("そん", .kun).contains("村"))
    }

    @Test("C5 空・空白だけ・ローマ字・漢字は 0 件")
    func invalidInputGivesNoResults() {
        for input in ["", "　 ", "mura", "村"] {
            #expect(characters(input, .on) == [], "\(input)")
            #expect(characters(input, .kun) == [], "\(input)")
        }
    }

    @Test("C6 ー を含む入力はかなとして扱う")
    func prolongedSoundMarkIsKana() {
        #expect(characters("ぺー", .kun).contains("頁"))
    }

    @Test("C7 結果は 総画数 → コードポイント 順(japonaise むらさき・むら)")
    func resultsAreOrderedByTotalStrokesThenCodePoint() {
        #expect(characters("むらさき", .kun) == ["茈", "紫"])
        #expect(characters("むら", .kun).prefix(8) == ["邨", "村", "邑", "茈", "党", "連", "紫", "群"])
    }

    @Test("C8 kJapanese の無い字(丆)はどの読みでも出ず、読みのある字は音 17,969 字・訓 7,512 字")
    func charactersWithoutReadingsNeverAppear() {
        let katakana = (0x30A1...0x30FA).compactMap(Unicode.Scalar.init).map { String($0) }
        let hiragana = (0x3041...0x3096).compactMap(Unicode.Scalar.init).map { String($0) }
        let onUnion = Set(katakana.flatMap { characters($0, .on) })
        let kunUnion = Set(hiragana.flatMap { characters($0, .kun) })

        #expect(!onUnion.contains("丆"))
        #expect(!kunUnion.contains("丆"))
        #expect(onUnion.count == 17_969)
        #expect(kunUnion.count == 7_512)
    }
}
