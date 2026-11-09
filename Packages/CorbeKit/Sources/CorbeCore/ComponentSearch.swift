import Foundation

// corbé タブの位置の選択肢(既定 指定なし)
public enum ComponentPosition: String, CaseIterable, Identifiable, Sendable {
    case unspecified = "指定なし"
    case hen = "偏"
    case tsukuri = "旁"
    case kanmuri = "冠"
    case ashi = "脚"
    case tare = "垂"
    case nyou = "繞"
    case kamae = "構"

    public var id: String { rawValue }

    public var title: String { rawValue }

    // 照合する部品トークンの位置。指定なしは nil(どの位置でもよく、字自身にも当たる)
    public var slot: ComponentSlot? {
        switch self {
        case .unspecified: return nil
        case .hen: return .hen
        case .tsukuri: return .tsukuri
        case .kanmuri: return .kanmuri
        case .ashi: return .ashi
        case .tare: return .tare
        case .nyou: return .nyou
        case .kamae: return .kamae
        }
    }
}

// 入力の 1 行(位置▼ + 部品テキスト)
public struct ComponentQueryRow: Sendable, Equatable {
    public var position: ComponentPosition
    public var text: String

    public init(position: ComponentPosition = .unspecified, text: String = "") {
        self.position = position
        self.text = text
    }
}

// 行ごとの解釈。空の行は無視、漢字でない部品を含む行は「部品として使えません」
public enum ComponentRowState: Sendable, Equatable {
    case empty
    case components([String])
    case unusable
}

public struct ComponentSearchResult: Sendable, Equatable {
    public let rows: [ComponentRowState]
    // 総画数 → コードポイント順
    public let entries: [KanjiEntry]

    // 全行が空(ヒントを出す)
    public var isEmptyQuery: Bool {
        rows.allSatisfy { $0 == .empty }
    }
}

// 部品テキストの解釈: NFKC → 空白を除いた各文字を部品にする → CJK Radicals Supplement を統合漢字へ移す
// (⺡ は NFKC で変わらないため EquivalentUnifiedIdeograph の対応表で移す)
public struct ComponentInputParser: Sendable {
    private let supplementEquivalents: [Unicode.Scalar: String]

    public init(supplementEquivalents: [Unicode.Scalar: String]) {
        self.supplementEquivalents = supplementEquivalents
    }

    // RadicalSupplementEquivalents.tsv: 1 行 = CJK Radicals Supplement の字 TAB 統合漢字
    public init(contents: String, fileName: String = "RadicalSupplementEquivalents.tsv") throws {
        var table: [Unicode.Scalar: String] = [:]
        var lineNumber = 0
        for line in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            lineNumber += 1
            if line.isEmpty {
                continue
            }
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count == 2,
                fields[0].unicodeScalars.count == 1,
                let source = fields[0].unicodeScalars.first,
                !fields[1].isEmpty else {
                throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
            }
            table[source] = String(fields[1])
        }
        self.init(supplementEquivalents: table)
    }

    public static func bundled() throws -> ComponentInputParser {
        try ComponentInputParser(contents: CorbeResources.text(named: "RadicalSupplementEquivalents", extension: "tsv"))
    }

    public func parse(_ text: String) -> ComponentRowState {
        var components: [String] = []
        for scalar in text.precomposedStringWithCompatibilityMapping.unicodeScalars {
            if scalar.properties.isWhitespace {
                continue
            }
            let mapped = supplementEquivalents[scalar] ?? String(scalar)
            guard mapped.unicodeScalars.allSatisfy(Self.isHanComponent) else {
                return .unusable
            }
            components.append(mapped)
        }
        return components.isEmpty ? .empty : .components(components)
    }

    // 統合漢字(拡張を含む)・互換漢字・Kangxi Radicals・CJK Radicals Supplement。CJK Strokes やかなは含まない
    static func isHanComponent(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x2E80...0x2EFF, 0x2F00...0x2FDF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF, 0x20000...0x3FFFF:
            return true
        default:
            return false
        }
    }
}

// corbé(部品 AND)の検索
public struct ComponentSearch: Sendable {
    private let index: KanjiIndex
    private let variants: ComponentVariants
    private let parser: ComponentInputParser

    public init(index: KanjiIndex, variants: ComponentVariants, parser: ComponentInputParser) {
        self.index = index
        self.variants = variants
        self.parser = parser
    }

    public func search(_ rows: [ComponentQueryRow]) -> ComponentSearchResult {
        let states = rows.map { parser.parse($0.text) }
        var requirements: [(slot: ComponentSlot?, candidates: Set<String>)] = []
        for (row, state) in zip(rows, states) {
            switch state {
            case .empty:
                continue
            case .unusable:
                return ComponentSearchResult(rows: states, entries: [])
            case .components(let components):
                for component in components {
                    requirements.append((slot: row.position.slot, candidates: variants.candidates(for: component)))
                }
            }
        }
        guard !requirements.isEmpty else {
            return ComponentSearchResult(rows: states, entries: [])
        }
        let matched = index.entries.filter { entry in
            requirements.allSatisfy { requirement in
                Self.entry(entry, satisfies: requirement.slot, candidates: requirement.candidates)
            }
        }
        return ComponentSearchResult(rows: states, entries: matched.sorted(by: KanjiEntry.strokeOrder))
    }

    private static func entry(_ entry: KanjiEntry, satisfies slot: ComponentSlot?, candidates: Set<String>) -> Bool {
        guard let slot else {
            return candidates.contains(entry.character)
                || entry.components.contains { candidates.contains($0.component) }
        }
        return entry.components.contains { $0.slot == slot && candidates.contains($0.component) }
    }
}
