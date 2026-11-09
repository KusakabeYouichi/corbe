import Foundation

// 部品の同値類(ComponentVariants.tsv)。1 行 = 部首番号 TAB 代表字 TAB 異体の形(半角空白区切り)。
// 代表字で探すと異体の形にも当たる(水 → 水 氵 氺)。異体の形で探したときは広げない(氵 → 氵)。
public struct ComponentVariants: Sendable {
    public struct RadicalClass: Sendable, Equatable {
        public let radical: Int
        public let representative: String
        public let variants: [String]

        public init(radical: Int, representative: String, variants: [String]) {
            self.radical = radical
            self.representative = representative
            self.variants = variants
        }
    }

    public let classes: [RadicalClass]
    private let candidatesByRepresentative: [String: Set<String>]

    public init(classes: [RadicalClass]) {
        self.classes = classes
        var candidates: [String: Set<String>] = [:]
        for radicalClass in classes {
            candidates[radicalClass.representative, default: [radicalClass.representative]]
                .formUnion(radicalClass.variants)
        }
        candidatesByRepresentative = candidates
    }

    public init(contents: String, fileName: String = "ComponentVariants.tsv") throws {
        var classes: [RadicalClass] = []
        var lineNumber = 0
        for line in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            lineNumber += 1
            if line.isEmpty {
                continue
            }
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count == 3, let radical = Int(fields[0]), !fields[1].isEmpty else {
                throw CorbeDataError.malformedLine(file: fileName, line: lineNumber)
            }
            classes.append(RadicalClass(
                radical: radical,
                representative: String(fields[1]),
                variants: fields[2].split(separator: " ").map(String.init)
            ))
        }
        self.init(classes: classes)
    }

    public static func bundled() throws -> ComponentVariants {
        try ComponentVariants(contents: CorbeResources.text(named: "ComponentVariants", extension: "tsv"))
    }

    public func radicalClass(forRadical radical: Int) -> RadicalClass? {
        classes.first { $0.radical == radical }
    }

    // 部品 c の照合候補。代表字なら {代表字} ∪ 異体の形、それ以外は {c} だけ
    public func candidates(for component: String) -> Set<String> {
        candidatesByRepresentative[component] ?? [component]
    }
}
