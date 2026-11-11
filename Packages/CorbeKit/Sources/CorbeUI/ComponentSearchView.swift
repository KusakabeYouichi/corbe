import CorbeCore
import SwiftUI

// élément / corbé: [位置▼][値] を 3 行。全行の AND で絞る。入力の変更で即時に検索し直す。
// 値は、位置が texte libre なら自由入力、それ以外はその位置の部首のプルダウン
struct ComponentSearchView: View {
    let library: KanjiLibrary
    let onCopy: (KanjiEntry) -> Void

    @State private var rows = Array(repeating: ComponentRowInput(), count: 3)
    @State private var result: ComponentSearchResult?
    // 部首の一覧を開いている行
    @State private var openRadicalList: Int?

    var body: some View {
        AdaptiveSearchLayout {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows.indices, id: \.self) { index in
                    rowView(index)
                }
            }
            .padding(12)
            .modifier(CardBackground())
        } results: {
            resultsView
        }
        .onAppear(perform: search)
        .onChange(of: rows) { search() }
        .onChange(of: library.loaded == nil) { search() }
    }

    @ViewBuilder
    private var resultsView: some View {
        if library.loaded == nil {
            SearchStatusView.notLoaded(error: library.loadError)
        } else if let result, !result.isEmptyQuery {
            if result.rows.contains(.unusable) {
                Spacer()
            } else if result.entries.isEmpty {
                SearchStatusView.noResults
            } else {
                KanjiResultGrid(items: StrokeListing.characterListItems(entries: result.entries), onCopy: onCopy)
            }
        } else {
            SearchStatusView(
                text: """
                位置を選ぶと、その位置の部首を選べます。texte libre では部品(木 氵 など)を自由に入れられます。\
                3 行すべてに当てはまる字を出します。\
                部首の形(木 日 寸 など)はそれ以上分けません。\
                にくづき は 月 で探します(偏 の 月 と にくづき は区別しません)。
                """,
                identifier: "emptyHint"
            )
        }
    }

    private func rowView(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                positionMenu(index)
                if rows[index].query.position == .unspecified {
                    JapaneseTextField(
                        text: $rows[index].query.text,
                        placeholder: "élément (ex. 木)",
                        accessibilityIdentifier: "componentText.\(index)"
                    )
                    .frame(height: 36)
                } else {
                    radicalButton(index)
                }
            }
            if let result, result.rows[index] == .unusable {
                Text("部品として使えません")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .accessibilityIdentifier("componentRowStatus.\(index)")
            }
        }
    }

    // 位置のプルダウン。ラベルを右の入力欄の手前まで広げ、余白も当たり判定にする。
    // texte libre はアイコンを付けず、ラベルの左端から書く
    private func positionMenu(_ index: Int) -> some View {
        let current = rows[index].query.position
        return Menu {
            ForEach(ComponentPosition.allCases) { position in
                Button {
                    selectPosition(position, row: index)
                } label: {
                    if let category = position.radicalCategory {
                        Label {
                            Text(position.title)
                        } icon: {
                            ComponentPositionIconImage.image(for: category)
                        }
                    } else {
                        Text(position.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                // 幅は最も長い『texte libre』に揃える(行ごとに右の入力欄の左端がずれないように)
                ZStack(alignment: .leading) {
                    Text(ComponentPosition.unspecified.title)
                        .hidden()
                    HStack(spacing: 6) {
                        if let category = current.radicalCategory {
                            ComponentPositionIconView(category: category)
                                .accessibilityIdentifier("componentPositionIcon.\(index).\(current.title)")
                        }
                        Text(current.title)
                    }
                }
                .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                Spacer(minLength: 8)
            }
            .foregroundStyle(Theme.accent)
            .frame(minHeight: 36)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityIdentifier("componentPosition.\(index)")
    }

    // 部首のボタン。指が触れた時点で吹き出しの部首の一覧を出す(離すまで待たない)。当たり判定は幅いっぱい。索引の読み込み前は押せない
    private func radicalButton(_ index: Int) -> some View {
        let position = rows[index].query.position
        return Button {
            openRadicalList(index)
        } label: {
            HStack(spacing: 6) {
                Text(rows[index].choice?.label ?? "選択")
                    .lineLimit(1)
                    .foregroundStyle(rows[index].choice == nil ? Color.secondary : Color.primary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressDownButtonStyle { openRadicalList(index) })
        .disabled(library.loaded == nil)
        .accessibilityIdentifier("componentForm.\(index)")
        .popover(isPresented: radicalListBinding(index)) {
            RadicalChoiceList(
                choices: library.loaded?.positionChoices.choices(for: position) ?? [],
                row: index
            ) { choice in
                // nil は先頭の Aucun(未選択に戻す)
                rows[index] = ComponentRowInput(
                    query: ComponentQueryRow(position: position, text: choice?.query ?? ""),
                    choice: choice
                )
                openRadicalList = nil
            }
            .presentationCompactAdaptation(.popover)
        }
    }

    private func openRadicalList(_ index: Int) {
        KeyboardDismissal.dismiss()
        openRadicalList = index
    }

    private func radicalListBinding(_ index: Int) -> Binding<Bool> {
        Binding {
            openRadicalList == index
        } set: { isPresented in
            if !isPresented, openRadicalList == index {
                openRadicalList = nil
            }
        }
    }

    // 位置と値は 1 回の代入で同時に変える(古い値のまま別の位置で検索しない)
    private func selectPosition(_ position: ComponentPosition, row index: Int) {
        guard rows[index].query.position != position else {
            return
        }
        rows[index] = ComponentRowInput(query: ComponentQueryRow(position: position))
    }

    private func search() {
        result = library.loaded?.componentSearch.search(rows.map(\.query))
    }
}

// 1 行の入力。位置付きの行は、選んだ部首の項目と、照合に使う字(query.text)を持つ
private struct ComponentRowInput: Equatable {
    var query = ComponentQueryRow()
    var choice: ComponentRadicalChoice?
}
