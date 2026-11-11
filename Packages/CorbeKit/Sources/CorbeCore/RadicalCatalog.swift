import Foundation
import Observation

// écritu の KanjiRadicalCatalog / RadicalPickerState から流用(Kangxi タブ)。
// 部首の位置カテゴリー(偏/旁/冠/脚/垂/繞/構/独立)と、その字形一覧。
// 分類の源泉は bushu.plist(écritu references/ から写したもの)。1字形が複数カテゴリーに
// 属してよく、位置を持たない部首は『独立』に入る。
public enum RadicalPositionCategory: String, CaseIterable, Identifiable, Sendable {
    case hen = "偏"
    case tsukuri = "旁"
    case kanmuri = "冠"
    case ashi = "脚"
    case tare = "垂"
    case nyou = "繞"
    case kamae = "構"
    case independent = "独立"

    public var id: String { rawValue }

    public var title: String { rawValue }

    public var reading: String {
        switch self {
        case .hen: return "へん"
        case .tsukuri: return "つくり"
        case .kanmuri: return "かんむり"
        case .ashi: return "あし"
        case .tare: return "たれ"
        case .nyou: return "にょう"
        case .kamae: return "かまえ"
        case .independent: return "その他"
        }
    }

    public var accessibilityLabel: String { "\(title)(\(reading))" }
}

// 流儀が分かれる部首の画数の選択肢(字形と画数)。
// 先頭の画数が Unihan の総画数の計算基準。corbé は設定画面を持たないので先頭で固定する
// (écritu はコンテナーアプリの設定で部首ごとに選べる)。
public struct RadicalStrokeOption: Equatable, Hashable, Sendable {
    public let form: String
    public let strokes: Int
}

public enum RadicalStrokeChoiceCatalog {
    // 部首番号 → 選択肢(écritu と同じ)
    static let optionsByRadical: [Int: [RadicalStrokeOption]] = [
        140: [.init(form: "⺾", strokes: 3), .init(form: "⺿", strokes: 4), .init(form: "艸", strokes: 6)],
        162: [.init(form: "⻌", strokes: 3), .init(form: "⻍", strokes: 4), .init(form: "辵", strokes: 7)],
        113: [.init(form: "礻", strokes: 4), .init(form: "⺭", strokes: 5), .init(form: "示", strokes: 5)],
        184: [.init(form: "飠", strokes: 7), .init(form: "⻟", strokes: 8), .init(form: "食", strokes: 9)]
    ]

    // 既定の選択 = 選択肢の先頭(Unihan 基準)
    public static func defaultOption(forRadical radical: Int) -> RadicalStrokeOption? {
        optionsByRadical[radical]?.first
    }
}

public struct RadicalForm: Identifiable, Equatable, Sendable {
    public let form: String
    public let radical: Int
    // その字形自体の画数(氵=3画/水=4画)。新字体で数えた値
    public let strokes: Int
    // 旧字体(伝統)で数えた画数。流儀が分かれる字形だけ持つ
    public let strokesTraditional: Int?
    public let name: String
    public let categories: [String]

    public var id: String { "\(radical)-\(form)" }

    // 一覧・見出しに出す字形。流儀が分かれる字形は既定の選択肢の字形
    public var displayForm: String {
        guard strokesTraditional != nil,
            let option = RadicalStrokeChoiceCatalog.defaultOption(forRadical: radical) else {
            return form
        }
        return option.form
    }

    // 一覧の画数。流儀が分かれる字形は既定の選択肢の画数、それ以外は plist の値そのまま
    public var listStrokes: Int {
        guard strokesTraditional != nil,
            let option = RadicalStrokeChoiceCatalog.defaultOption(forRadical: radical) else {
            return strokes
        }
        return option.strokes
    }
}

public struct RadicalCatalog: Sendable {
    public let allForms: [RadicalForm]

    public init(allForms: [RadicalForm]) {
        self.allForms = allForms
    }

    public init(plistData data: Data) throws {
        guard let raw = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [[String: Any]] else {
            throw CorbeDataError.malformedPropertyList(file: "bushu.plist")
        }
        let forms: [RadicalForm] = raw.compactMap { entry in
            guard let form = entry["form"] as? String,
                let radical = entry["radical"] as? Int,
                let strokes = entry["strokes"] as? Int,
                let name = entry["name"] as? String,
                let categories = entry["categories"] as? [String] else {
                return nil
            }
            return RadicalForm(
                form: form,
                radical: radical,
                strokes: strokes,
                strokesTraditional: entry["strokesTraditional"] as? Int,
                name: name,
                categories: categories
            )
        }
        self.init(allForms: forms)
    }

    public static func bundled() throws -> RadicalCatalog {
        try RadicalCatalog(plistData: CorbeResources.data(named: "bushu", extension: "plist"))
    }

    // カテゴリー内は画数順(同画数は部首番号順)。部首を探す手掛かりが画数のため
    public func forms(in category: RadicalPositionCategory) -> [RadicalForm] {
        allForms
            .filter { $0.categories.contains(category.rawValue) }
            .sorted { lhs, rhs in
                lhs.listStrokes != rhs.listStrokes ? lhs.listStrokes < rhs.listStrokes : lhs.radical < rhs.radical
            }
    }
}

// 部首ピッカーの選択(分類と、開いている部首)。分類を変えたら部首の選択は閉じる。
@Observable
@MainActor
public final class RadicalPickerState {
    public private(set) var selectedCategory: RadicalPositionCategory = .hen
    public private(set) var selectedForm: RadicalForm?

    public init() {}

    public func selectCategory(_ category: RadicalPositionCategory) {
        selectedCategory = category
        selectedForm = nil
    }

    public func selectForm(_ form: RadicalForm) {
        selectedForm = form
    }

    public func clearForm() {
        selectedForm = nil
    }
}
