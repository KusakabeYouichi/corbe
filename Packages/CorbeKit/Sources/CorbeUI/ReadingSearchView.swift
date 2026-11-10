import CorbeCore
import SwiftUI

// Lecture / chinoise(音読み)・japonaise(訓読み): 読みの前方一致。ひらがな・カタカナどちらで入れてもよい
struct ReadingSearchView: View {
    let kind: ReadingKind
    let library: KanjiLibrary
    let onCopy: (KanjiEntry) -> Void

    @State private var input = ""
    @State private var entries: [KanjiEntry] = []

    private var identifierSuffix: String {
        kind == .on ? "on" : "kun"
    }

    private var hint: String {
        let target = kind == .on ? "音読み" : "訓読み"
        return """
        \(target)をかなで入れると、その読みで始まる字を出します(ひらがな・カタカナどちらでも)。\
        読みのデータ(Unihan の kJapanese)がある字だけが対象です。
        """
    }

    var body: some View {
        AdaptiveSearchLayout {
            // 部品の入力欄と同じ欄(日本語キーボードで開き、キーボードの上に「完了」を出す)
            JapaneseTextField(
                text: $input,
                placeholder: kind == .on ? "音読み(例 そん)" : "訓読み(例 むら)",
                accessibilityIdentifier: "readingField.\(identifierSuffix)"
            )
                .frame(height: 36)
                .padding(12)
                .modifier(CardBackground())
        } results: {
            resultsView
        }
        .onAppear(perform: search)
        .onChange(of: input) { search() }
        .onChange(of: library.loaded == nil) { search() }
    }

    @ViewBuilder
    private var resultsView: some View {
        if library.loaded == nil {
            SearchStatusView.notLoaded(error: library.loadError)
        } else if ReadingSearch.normalize(input, kind: kind) == nil {
            SearchStatusView(text: hint, identifier: "emptyHint")
        } else if entries.isEmpty {
            SearchStatusView(text: "当てはまる字がありません", identifier: "noResults")
        } else {
            KanjiResultGrid(items: StrokeListing.characterListItems(entries: entries), onCopy: onCopy)
        }
    }

    private func search() {
        entries = library.loaded?.readingSearch.search(input, kind: kind) ?? []
    }
}
