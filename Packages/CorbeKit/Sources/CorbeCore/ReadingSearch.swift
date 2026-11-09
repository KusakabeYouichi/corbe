import Foundation

public enum ReadingKind: Sendable {
    // chinoise(音読み。カタカナで照合)
    case on
    // japonaise(訓読み。ひらがなで照合)
    case kun
}

// chinoise / japonaise(読みの前方一致)。母集団は kJapanese を持つ字だけ
public struct ReadingSearch: Sendable {
    private let index: KanjiIndex

    public init(index: KanjiIndex) {
        self.index = index
    }

    // 総画数 → コードポイント順。入力が空・かな以外を含むときは空
    public func search(_ input: String, kind: ReadingKind) -> [KanjiEntry] {
        guard let key = Self.normalize(input, kind: kind) else {
            return []
        }
        let matched = index.entries.filter { entry in
            let readings = kind == .on ? entry.onReadings : entry.kunReadings
            return readings.contains { $0.hasPrefix(key) }
        }
        return matched.sorted(by: KanjiEntry.strokeOrder)
    }

    // NFKC → 前後の空白を除く → 音はカタカナへ、訓はひらがなへ。空・かな(と ー)以外を含むなら nil
    public static func normalize(_ input: String, kind: ReadingKind) -> String? {
        let trimmed = input.precomposedStringWithCompatibilityMapping.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        var scalars = String.UnicodeScalarView()
        for scalar in trimmed.unicodeScalars {
            switch scalar.value {
            case 0x3041...0x3096:
                scalars.append(kind == .on ? Unicode.Scalar(scalar.value + 0x60)! : scalar)
            case 0x30A1...0x30F6:
                scalars.append(kind == .kun ? Unicode.Scalar(scalar.value - 0x60)! : scalar)
            case 0x30F7...0x30FA, 0x30FC:
                scalars.append(scalar)
            default:
                return nil
            }
        }
        return String(scalars)
    }
}
