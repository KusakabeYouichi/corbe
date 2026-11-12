import Foundation

public enum CorbeDataError: Error, Equatable {
    case missingResource(String)
    case malformedLine(file: String, line: Int)
    case malformedPropertyList(file: String)
}

// KanjiIndex.tsv(tools/build_kanji_index.py の生成物)を読む。
// 1 行 = 字 TAB 部首番号 TAB 部首内画数 TAB 総画数 TAB 区点 TAB 音読み TAB 訓読み TAB 部品
//   TAB 常用(1 か空) TAB 人名用(1 か空) TAB 教育漢字の学年(1〜6 か空) TAB JLPT の級(5〜1 か空)。
// ファイルの並び(部首番号 → 総画数 → 部首内画数 → コードポイント)をそのまま保つ。
public struct KanjiIndex: Sendable {
    public let entries: [KanjiEntry]

    public init(entries: [KanjiEntry]) {
        self.entries = entries
    }

    public init(contents: String, fileName: String = "KanjiIndex.tsv") throws {
        var entries: [KanjiEntry] = []
        var lineNumber = 0
        for line in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            lineNumber += 1
            if line.isEmpty {
                continue
            }
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count == 12,
                !fields[0].isEmpty,
                let radical = Int(fields[1]),
                let residual = Int(fields[2]),
                let total = Int(fields[3]),
                let isJoyo = Self.flag(fields[8]),
                let isJinmeiyo = Self.flag(fields[9]),
                let grade = Self.optionalInt(fields[10], in: 1...6),
                let jlpt = Self.optionalInt(fields[11], in: 1...5) else {
                throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
            }
            var components: [ComponentToken] = []
            for token in fields[7].split(separator: " ") {
                guard let parsed = ComponentToken(token: token) else {
                    throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
                }
                components.append(parsed)
            }
            var kunParts: [KunReading] = []
            for word in fields[6].split(separator: " ") {
                guard let parsed = KunReading(marked: word) else {
                    throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
                }
                kunParts.append(parsed)
            }
            entries.append(KanjiEntry(
                character: String(fields[0]),
                radical: radical,
                residualStrokes: residual,
                totalStrokes: total,
                kuten: String(fields[4]),
                onReadings: fields[5].split(separator: " ").map(String.init),
                kunParts: kunParts,
                components: components,
                isJoyo: isJoyo,
                isJinmeiyo: isJinmeiyo,
                schoolGrade: grade,
                jlptLevel: jlpt
            ))
        }
        self.init(entries: entries)
    }

    // "1" → true、空 → false、それ以外 → nil(形の誤り)
    private static func flag(_ field: Substring) -> Bool? {
        switch field {
        case "1": true
        case "": false
        default: nil
        }
    }

    // 空 → .some(nil)、範囲内の数 → .some(値)、それ以外 → nil(形の誤り)
    private static func optionalInt(_ field: Substring, in range: ClosedRange<Int>) -> Int?? {
        if field.isEmpty {
            return .some(nil)
        }
        guard let value = Int(field), range.contains(value) else {
            return nil
        }
        return .some(value)
    }

    // パッケージに同梱した索引
    public static func bundled() throws -> KanjiIndex {
        try KanjiIndex(contents: CorbeResources.text(named: "KanjiIndex", extension: "tsv"))
    }

    // 部首の字(索引順 = 総画数 → 部首内画数 → コードポイント)
    public func entries(forRadical radical: Int) -> [KanjiEntry] {
        entries.filter { $0.radical == radical }
    }
}

// パッケージに同梱した資源(KanjiIndex.tsv / ComponentVariants.tsv / RadicalSupplementEquivalents.tsv / ComponentInputAliases.tsv / bushu.plist)
enum CorbeResources {
    static func data(named name: String, extension fileExtension: String) throws -> Data {
        try Data(contentsOf: url(named: name, extension: fileExtension))
    }

    static func text(named name: String, extension fileExtension: String) throws -> String {
        try String(contentsOf: url(named: name, extension: fileExtension), encoding: .utf8)
    }

    private static func url(named name: String, extension fileExtension: String) throws -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: fileExtension) else {
            throw CorbeDataError.missingResource("\(name).\(fileExtension)")
        }
        return url
    }
}
