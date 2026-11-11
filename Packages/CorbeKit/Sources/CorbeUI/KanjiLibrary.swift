import CorbeCore
import Foundation
import Observation

// 同梱の索引・同値類・部首カタログ。起動直後にバックグラウンドで読み、読み終わるまでは nil
// (各タブは『読み込み中』を出し、読み終わったら最新の入力で検索し直す)
@Observable
@MainActor
final class KanjiLibrary {
    struct Loaded: Sendable {
        let index: KanjiIndex
        let componentSearch: ComponentSearch
        let readingSearch: ReadingSearch
        let catalog: RadicalCatalog
        // corbé タブの位置ごとの部首プルダウンの選択肢
        let positionChoices: ComponentPositionChoices
    }

    private(set) var loaded: Loaded?
    private(set) var loadError: String?

    func load() async {
        guard loaded == nil else {
            return
        }
        let result = await Task.detached(priority: .userInitiated) { () -> Result<Loaded, Error> in
            Result {
                let index = try KanjiIndex.bundled()
                let variants = try ComponentVariants.bundled()
                let catalog = try RadicalCatalog.bundled()
                return Loaded(
                    index: index,
                    componentSearch: ComponentSearch(
                        index: index,
                        variants: variants,
                        parser: try ComponentInputParser.bundled()
                    ),
                    readingSearch: ReadingSearch(index: index),
                    catalog: catalog,
                    positionChoices: ComponentPositionChoices(catalog: catalog, variants: variants, index: index)
                )
            }
        }.value
        switch result {
        case .success(let value):
            loaded = value
        case .failure(let error):
            loadError = "\(error)"
        }
    }
}
