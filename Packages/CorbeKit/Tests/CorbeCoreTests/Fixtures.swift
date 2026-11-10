import Foundation
@testable import CorbeCore

// 同梱の生成物(KanjiIndex.tsv / ComponentVariants.tsv / RadicalSupplementEquivalents.tsv / ComponentInputAliases.tsv / bushu.plist)を
// 1 回だけ読んで各テストで使う
enum Bundled {
    static let index: KanjiIndex = {
        do {
            return try KanjiIndex.bundled()
        } catch {
            fatalError("KanjiIndex.tsv を読めません: \(error)")
        }
    }()

    static let variants: ComponentVariants = {
        do {
            return try ComponentVariants.bundled()
        } catch {
            fatalError("ComponentVariants.tsv を読めません: \(error)")
        }
    }()

    static let parser: ComponentInputParser = {
        do {
            return try ComponentInputParser.bundled()
        } catch {
            fatalError("RadicalSupplementEquivalents.tsv / ComponentInputAliases.tsv を読めません: \(error)")
        }
    }()

    static let catalog: RadicalCatalog = {
        do {
            return try RadicalCatalog.bundled()
        } catch {
            fatalError("bushu.plist を読めません: \(error)")
        }
    }()

    static let componentSearch = ComponentSearch(index: index, variants: variants, parser: parser)

    static let readingSearch = ReadingSearch(index: index)

    static let positionChoices = ComponentPositionChoices(catalog: catalog, variants: variants, index: index)

    static func entry(_ character: String) -> KanjiEntry? {
        index.entries.first { $0.character == character }
    }

    // 部品トークンを "L:木" の形の文字列で返す(期待値を読みやすく書くため)
    static func tokens(_ character: String) -> [String] {
        entry(character)?.components.map { "\($0.slot.rawValue):\($0.component)" } ?? []
    }

    // 行を (位置, テキスト) で渡して、結果の字を返す
    static func characters(_ rows: (ComponentPosition, String)...) -> [String] {
        componentSearch.search(rows.map { ComponentQueryRow(position: $0.0, text: $0.1) }).entries.map(\.character)
    }
}
