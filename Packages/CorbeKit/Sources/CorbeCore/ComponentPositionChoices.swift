import Foundation

// corbé タブの部首プルダウンの 1 項目。同じ位置・同じ部首番号の字形(辶 辵 など)は 1 項目にまとめる
public struct ComponentRadicalChoice: Identifiable, Equatable, Sendable {
    public let radical: Int
    // bushu.plist の form を画数順(同画数はコードポイント順)に
    public let forms: [String]
    // 読み。字形の順に、重複を除く
    public let names: [String]
    // 項目内の最小の画数(既定の数え方)。見出しと並びに使う
    public let strokes: Int
    // 選んだときに行へ入れる字。部首の代表字(異体にも当たる)。130(肉)だけは 月
    // (J 字形の IDS は にくづき を 月 と書くため)
    public let query: String

    public var id: Int { radical }

    // 『辶 辵 しんにょう』『⺗ 心 したごころ・こころ』
    public var label: String {
        (forms + [names.joined(separator: "・")]).joined(separator: " ")
    }
}

// 画数の見出しごとのまとまり
public struct ComponentRadicalSection: Identifiable, Equatable, Sendable {
    public let strokes: Int
    public let choices: [ComponentRadicalChoice]

    public var id: Int { strokes }
}

// 位置 → 部首の選択肢。並びは Kangxi の部首一覧と同じ(画数 → 部首番号)。
// その位置で選んで 1 字も当たらない項目は除く(索引のその位置に現れる部品と、照合候補の交差が空の項目)
public struct ComponentPositionChoices: Sendable {
    // 部首 130(肉)の照合に使う字
    private static let nikuzukiQuery = "月"

    private let sectionsByPosition: [ComponentPosition: [ComponentRadicalSection]]

    public init(catalog: RadicalCatalog, variants: ComponentVariants, index: KanjiIndex) {
        var componentsBySlot: [ComponentSlot: Set<String>] = [:]
        for entry in index.entries {
            for token in entry.components {
                componentsBySlot[token.slot, default: []].insert(token.component)
            }
        }
        var sections: [ComponentPosition: [ComponentRadicalSection]] = [:]
        for position in ComponentPosition.allCases {
            guard let category = position.radicalCategory, let slot = position.slot else {
                continue
            }
            let present = componentsBySlot[slot] ?? []
            let choices = Self.choices(in: category, catalog: catalog, variants: variants)
                .filter { !variants.candidates(for: $0.query).isDisjoint(with: present) }
            sections[position] = Self.sections(choices)
        }
        sectionsByPosition = sections
    }

    // texte libre は空
    public func sections(for position: ComponentPosition) -> [ComponentRadicalSection] {
        sectionsByPosition[position] ?? []
    }

    public func choices(for position: ComponentPosition) -> [ComponentRadicalChoice] {
        sections(for: position).flatMap(\.choices)
    }

    private static func choices(
        in category: RadicalPositionCategory,
        catalog: RadicalCatalog,
        variants: ComponentVariants
    ) -> [ComponentRadicalChoice] {
        let forms = catalog.allForms.filter { $0.categories.contains(category.rawValue) }
        let formsByRadical = Dictionary(grouping: forms, by: \.radical)
        let choices: [ComponentRadicalChoice] = formsByRadical.compactMap { radical, forms in
            guard let representative = variants.radicalClass(forRadical: radical)?.representative else {
                return nil
            }
            let ordered = forms.sorted { lhs, rhs in
                lhs.listStrokes != rhs.listStrokes
                    ? lhs.listStrokes < rhs.listStrokes
                    : lhs.form.unicodeScalars.lexicographicallyPrecedes(rhs.form.unicodeScalars) { $0.value < $1.value }
            }
            var names: [String] = []
            for form in ordered where !names.contains(form.name) {
                names.append(form.name)
            }
            return ComponentRadicalChoice(
                radical: radical,
                forms: ordered.map(\.form),
                names: names,
                strokes: ordered[0].listStrokes,
                query: radical == 130 ? nikuzukiQuery : representative
            )
        }
        return choices.sorted { lhs, rhs in
            lhs.strokes != rhs.strokes ? lhs.strokes < rhs.strokes : lhs.radical < rhs.radical
        }
    }

    private static func sections(_ choices: [ComponentRadicalChoice]) -> [ComponentRadicalSection] {
        var sections: [ComponentRadicalSection] = []
        var current: [ComponentRadicalChoice] = []
        for choice in choices {
            if let last = current.last, last.strokes != choice.strokes {
                sections.append(ComponentRadicalSection(strokes: last.strokes, choices: current))
                current = []
            }
            current.append(choice)
        }
        if let last = current.last {
            sections.append(ComponentRadicalSection(strokes: last.strokes, choices: current))
        }
        return sections
    }
}
