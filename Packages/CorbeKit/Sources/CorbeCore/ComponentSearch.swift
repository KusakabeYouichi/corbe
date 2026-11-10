import Foundation

// corbé タブの位置の選択肢(既定 texte libre = 位置を問わない自由入力)
public enum ComponentPosition: String, CaseIterable, Identifiable, Sendable {
    case unspecified = "texte libre"
    case hen = "偏"
    case tsukuri = "旁"
    case kanmuri = "冠"
    case ashi = "脚"
    case tare = "垂"
    case nyou = "繞"
    case kamae = "構"

    public var id: String { rawValue }

    public var title: String { rawValue }

    // 照合する部品トークンの位置。texte libre は nil(どの位置でもよく、字自身にも当たる)
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

    // 部首の選択肢と位置アイコンに使う bushu.plist の位置カテゴリー。texte libre は nil
    public var radicalCategory: RadicalPositionCategory? {
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
// (⺡ は NFKC で変わらないため EquivalentUnifiedIdeograph の対応表で移す)。
// 読み替え表にある入力字は、そのまま 1 つの部品として受け、照合はその表の部品のどれか(OR)で行う
public struct ComponentInputParser: Sendable {
    private let supplementEquivalents: [Unicode.Scalar: String]
    private let aliases: [String: [String]]

    public init(supplementEquivalents: [Unicode.Scalar: String], aliases: [String: [String]] = [:]) {
        self.supplementEquivalents = supplementEquivalents
        self.aliases = aliases
    }

    // RadicalSupplementEquivalents.tsv: 1 行 = CJK Radicals Supplement の字 TAB 統合漢字
    // ComponentInputAliases.tsv: 1 行 = 入力字 TAB 照合する部品(半角空白区切り)
    public init(
        contents: String,
        aliasContents: String = "",
        fileName: String = "RadicalSupplementEquivalents.tsv",
        aliasFileName: String = "ComponentInputAliases.tsv"
    ) throws {
        var table: [Unicode.Scalar: String] = [:]
        for (lineNumber, fields) in try Self.rows(contents, fileName: fileName) {
            guard fields[0].unicodeScalars.count == 1, let source = fields[0].unicodeScalars.first else {
                throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
            }
            table[source] = String(fields[1])
        }
        var aliases: [String: [String]] = [:]
        for (lineNumber, fields) in try Self.rows(aliasContents, fileName: aliasFileName) {
            let targets = fields[1].split(separator: " ").map(String.init)
            guard fields[0].unicodeScalars.count == 1,
                !targets.isEmpty,
                targets.allSatisfy({ $0.unicodeScalars.allSatisfy(Self.isHanComponent) }) else {
                throw CorbeDataError.malformedLine(file: aliasFileName, line: lineNumber)
            }
            aliases[String(fields[0])] = targets
        }
        self.init(supplementEquivalents: table, aliases: aliases)
    }

    public static func bundled() throws -> ComponentInputParser {
        try ComponentInputParser(
            contents: CorbeResources.text(named: "RadicalSupplementEquivalents", extension: "tsv"),
            aliasContents: CorbeResources.text(named: "ComponentInputAliases", extension: "tsv")
        )
    }

    // 2 列の TSV の行(空行は飛ばす)。列数が違う・値が空の行はエラー
    private static func rows(_ contents: String, fileName: String) throws -> [(Int, [Substring])] {
        var rows: [(Int, [Substring])] = []
        var lineNumber = 0
        for line in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            lineNumber += 1
            if line.isEmpty {
                continue
            }
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count == 2, !fields[0].isEmpty, !fields[1].isEmpty else {
                throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
            }
            rows.append((lineNumber, fields))
        }
        return rows
    }

    // 部品 c で照合する字。読み替え表にあればその部品(どれかに当たればよい)、無ければ c 自身
    public func matchTargets(for component: String) -> [String] {
        aliases[component] ?? [component]
    }

    public func parse(_ text: String) -> ComponentRowState {
        var components: [String] = []
        for scalar in text.precomposedStringWithCompatibilityMapping.unicodeScalars {
            if scalar.properties.isWhitespace {
                continue
            }
            if aliases[String(scalar)] != nil {
                components.append(String(scalar))
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
                    let candidates = parser.matchTargets(for: component).reduce(into: Set<String>()) { result, target in
                        result.formUnion(variants.candidates(for: target))
                    }
                    requirements.append((slot: row.position.slot, candidates: candidates))
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
