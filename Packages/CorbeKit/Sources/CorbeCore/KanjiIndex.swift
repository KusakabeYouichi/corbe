import Foundation

public enum CorbeDataError: Error, Equatable {
    case missingResource(String)
    case malformedLine(file: String, line: Int)
    case malformedPropertyList(file: String)
}

// KanjiIndex.tsv(tools/build_kanji_index.py の生成物)を読む。
// 1 行 = 字 TAB 部首番号 TAB 部首内画数 TAB 総画数 TAB 区点 TAB 音読み TAB 訓読み TAB 部品。
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
            guard fields.count == 8,
                !fields[0].isEmpty,
                let radical = Int(fields[1]),
                let residual = Int(fields[2]),
                let total = Int(fields[3]) else {
                throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
            }
            var components: [ComponentToken] = []
            for token in fields[7].split(separator: " ") {
                guard let parsed = ComponentToken(token: token) else {
                    throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
                }
                components.append(parsed)
            }
            entries.append(KanjiEntry(
                character: String(fields[0]),
                radical: radical,
                residualStrokes: residual,
                totalStrokes: total,
                kuten: String(fields[4]),
                onReadings: fields[5].split(separator: " ").map(String.init),
                kunReadings: fields[6].split(separator: " ").map(String.init),
                components: components
            ))
        }
        self.init(entries: entries)
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
