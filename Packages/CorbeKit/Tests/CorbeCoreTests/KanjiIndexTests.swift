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

    @Test("A20 区分: 村 は常用・教育 1 年・JLPT N2、存 は教育 6 年・N3、萬 は人名用のみ、鬱 は常用のみ、丂 はどれでもない")
    func categoryColumns() throws {
        let mura = try #require(Bundled.entry("村"))
        #expect((mura.isJoyo, mura.isJinmeiyo, mura.schoolGrade, mura.jlptLevel) == (true, false, 1, 2))
        let son = try #require(Bundled.entry("存"))
        #expect((son.isJoyo, son.schoolGrade, son.jlptLevel) == (true, 6, 3))
        let man = try #require(Bundled.entry("萬"))
        #expect((man.isJoyo, man.isJinmeiyo, man.schoolGrade, man.jlptLevel) == (false, true, nil, nil))
        let utsu = try #require(Bundled.entry("鬱"))
        #expect((utsu.isJoyo, utsu.isJinmeiyo, utsu.schoolGrade, utsu.jlptLevel) == (true, false, nil, nil))
        let kou = try #require(Bundled.entry("丂"))
        #expect((kou.isJoyo, kou.isJinmeiyo, kou.schoolGrade, kou.jlptLevel) == (false, false, nil, nil))
    }

    @Test("A21 件数: 常用 2,139(許容字体 剥 填 頬 と 叱 を含む)・教育 1,026(学年別 80/160/200/202/193/191)・JLPT 2,211")
    func categoryCounts() {
        let entries = Bundled.index.entries
        #expect(entries.filter(\.isJoyo).count == 2_139)
        let grades = (1...6).map { grade in entries.filter { $0.schoolGrade == grade }.count }
        #expect(grades == [80, 160, 200, 202, 193, 191])
        #expect(entries.filter { $0.jlptLevel != nil }.count == 2_211)
        #expect(entries.allSatisfy { $0.schoolGrade == nil || $0.isJoyo })
        #expect(!entries.contains { $0.isJoyo && $0.isJinmeiyo })
    }

    @Test("A22 区分の列の形が違う行は読み込みで弾く(常用 2・学年 7・JLPT 0)")
    func malformedCategoryColumnsAreRejected() {
        let base = "村\t75\t3\t7\t34-28\tソン\tむら\tL:木 R:寸"
        for tail in ["\t2\t\t1\t2", "\t1\t\t7\t2", "\t1\t\t1\t0", "\t1\t\t1"] {
            #expect(throws: CorbeDataError.malformedLine(file: "KanjiIndex.tsv", line: 1)) {
                try KanjiIndex(contents: base + tail)
            }
        }
        #expect((try? KanjiIndex(contents: base + "\t1\t\t1\t2"))?.entries.first?.schoolGrade == 1)
    }

    @Test("A23 送り仮名: 明 は あか+るい・あ+ける、境目の分からない ひかり と、送り仮名の無い 村 の むら は全体が語幹")
    func okuriganaBoundaries() throws {
        let akari = try #require(Bundled.entry("明"))
        #expect(akari.kunParts.contains(KunReading(stem: "あか", okurigana: "るい")))
        #expect(akari.kunParts.contains(KunReading(stem: "あ", okurigana: "ける")))
        #expect(akari.kunParts.contains(KunReading(stem: "ひかり")))
        #expect(try #require(Bundled.entry("村")).kunParts == [KunReading(stem: "むら")])
    }

    @Test("A24 境目を入れても、検索に使う訓読みは境目なしのまま(明 の先頭 3 件は あかり あかるい あかるむ)")
    func kunReadingsStayPlain() throws {
        let entry = try #require(Bundled.entry("明"))

        #expect(Array(entry.kunReadings.prefix(3)) == ["あかり", "あかるい", "あかるむ"])
        #expect(entry.kunReadings == entry.kunParts.map(\.text))
    }

    @Test("A25 境目の形が違う訓読みは読み込みで弾く(. が先頭・末尾・2 つ)")
    func malformedOkuriganaIsRejected() {
        for kun in [".あかるい", "あかるい.", "あ.か.るい"] {
            #expect(throws: CorbeDataError.malformedLine(file: "KanjiIndex.tsv", line: 1)) {
                try KanjiIndex(contents: "明\t72\t4\t8\t44-32\tメイ\t\(kun)\tL:日 R:月\t1\t\t2\t4")
            }
        }
    }
}
