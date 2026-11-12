import Foundation

// 部品トークンの位置(KanjiIndex.tsv の位置記号)。他(O)は ⿲ ⿳ の中・囲みの内側・⿾ ⿿ ㇯ の項
public enum ComponentSlot: Character, Sendable, CaseIterable {
    case hen = "L"
    case tsukuri = "R"
    case kanmuri = "T"
    case ashi = "B"
    case tare = "W"
    case nyou = "N"
    case kamae = "K"
    case other = "O"
}

// 部品トークン(位置記号:部品)。最上位の演算子が決めた位置を、子孫の部品も受け継ぐ
public struct ComponentToken: Sendable, Hashable {
    public let slot: ComponentSlot
    public let component: String

    public init(slot: ComponentSlot, component: String) {
        self.slot = slot
        self.component = component
    }

    // "L:木" の形を読む。形が違えば nil
    init?(token: Substring) {
        guard let separator = token.firstIndex(of: ":"),
            token.distance(from: token.startIndex, to: separator) == 1,
            let slot = ComponentSlot(rawValue: token[token.startIndex]) else {
            return nil
        }
        let component = token[token.index(after: separator)...]
        guard !component.isEmpty else {
            return nil
        }
        self.init(slot: slot, component: String(component))
    }
}

// 訓読みの 1 件。送り仮名の境目が分かるものだけ okurigana を持つ(『あか.るい』→ あか + るい)。
// 境目の出典は KANJIDIC2。同じ読みが無いものは境目が分からないので、全体を stem に入れる
public struct KunReading: Sendable, Hashable {
    public let stem: String
    public let okurigana: String

    public var text: String { stem + okurigana }

    public init(stem: String, okurigana: String = "") {
        self.stem = stem
        self.okurigana = okurigana
    }

    // "あか.るい" の形を読む(. が無ければ全体が stem)。. の前後が空、. が 2 つ以上なら nil
    public init?(marked: some StringProtocol) {
        let parts = marked.split(separator: ".", omittingEmptySubsequences: false)
        switch parts.count {
        case 1 where !parts[0].isEmpty:
            self.init(stem: String(parts[0]))
        case 2 where !parts[0].isEmpty && !parts[1].isEmpty:
            self.init(stem: String(parts[0]), okurigana: String(parts[1]))
        default:
            return nil
        }
    }
}

// 索引の 1 字(KanjiIndex.tsv の 1 行)
public struct KanjiEntry: Sendable, Hashable, Identifiable {
    public let character: String
    public let radical: Int
    public let residualStrokes: Int
    // Unihan kTotalStrokes の先頭。無い字は 0
    public let totalStrokes: Int
    // JIS X 0208 の区点("34-28")。無い字は空
    public let kuten: String
    public let onReadings: [String]
    // 検索で毎回引くので、境目を除いた読みも持っておく(kunParts の text と同じ並び)
    public let kunReadings: [String]
    public let kunParts: [KunReading]
    public let components: [ComponentToken]
    // 常用漢字・人名用漢字(Unihan kJoyoKanji / kJinmeiyoKanji。許容字体・異体として載る字も含む)
    public let isJoyo: Bool
    public let isJinmeiyo: Bool
    // 教育漢字の学年(学年別漢字配当表)。教育漢字でなければ nil
    public let schoolGrade: Int?
    // JLPT の級(5 = N5 〜 1 = N1。tanos.co.uk の非公式の表)。無ければ nil
    public let jlptLevel: Int?

    public var id: String { character }

    public var codePoint: UInt32 {
        character.unicodeScalars.first?.value ?? 0
    }

    // "U+6751"
    public var codePointLabel: String {
        String(format: "U+%04X", codePoint)
    }

    public init(
        character: String,
        radical: Int,
        residualStrokes: Int,
        totalStrokes: Int,
        kuten: String,
        onReadings: [String],
        kunParts: [KunReading],
        components: [ComponentToken],
        isJoyo: Bool = false,
        isJinmeiyo: Bool = false,
        schoolGrade: Int? = nil,
        jlptLevel: Int? = nil
    ) {
        self.character = character
        self.radical = radical
        self.residualStrokes = residualStrokes
        self.totalStrokes = totalStrokes
        self.kuten = kuten
        self.onReadings = onReadings
        self.kunReadings = kunParts.map(\.text)
        self.kunParts = kunParts
        self.components = components
        self.isJoyo = isJoyo
        self.isJinmeiyo = isJinmeiyo
        self.schoolGrade = schoolGrade
        self.jlptLevel = jlptLevel
    }

    // 検索結果の並び(総画数 → コードポイント)
    public static func strokeOrder(_ lhs: KanjiEntry, _ rhs: KanjiEntry) -> Bool {
        lhs.totalStrokes != rhs.totalStrokes ? lhs.totalStrokes < rhs.totalStrokes : lhs.codePoint < rhs.codePoint
    }
}
