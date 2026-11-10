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
                SearchStatusView(text: "当てはまる字がありません", identifier: "noResults")
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
                // 幅は最も長い「texte libre」に揃える(行ごとに右の入力欄の左端がずれないように)
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

// 部首の一覧(吹き出しの中身)。先頭は未選択に戻す Aucun、続いて 字形(明朝・列幅を固定)と 読み。
// 画数の区切りは項目の上端に重ねた線で描き、行の高さを取らない。画数は線の右端の下に小さく書く(どの画数の始まりか分かるように)
private struct RadicalChoiceList: View {
    let choices: [ComponentRadicalChoice]
    let row: Int
    let onSelect: (ComponentRadicalChoice?) -> Void

    private static let rowHeight: CGFloat = 44
    private static let formColumnWidth: CGFloat = 64
    private static let verticalInset: CGFloat = 8

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                noneItem
                ForEach(Array(choices.enumerated()), id: \.element.id) { offset, choice in
                    item(choice)
                        .overlay(alignment: .top) {
                            if offset == 0 || choices[offset - 1].strokes != choice.strokes {
                                strokeDivider(choice.strokes)
                            }
                        }
                }
            }
        }
        .contentMargins(.vertical, Self.verticalInset, for: .scrollContent)
        .frame(width: 280)
        .frame(idealHeight: CGFloat(choices.count + 1) * Self.rowHeight + Self.verticalInset * 2, maxHeight: 520)
        .accessibilityIdentifier("componentFormList.\(row)")
    }

    // 未選択に戻す項目。部首と見分けるため斜体にし、色はボタンの未選択表示(「選択」)と同じ secondary にする
    private var noneItem: some View {
        Button {
            onSelect(nil)
        } label: {
            HStack(spacing: 0) {
                Text("Aucun")
                    .italic()
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("componentFormNone.\(row)")
    }

    private func item(_ choice: ComponentRadicalChoice) -> some View {
        Button {
            onSelect(choice)
        } label: {
            HStack(spacing: 0) {
                Text(choice.forms.joined(separator: " "))
                    .font(.custom(Theme.minchoFontName, size: 22))
                    .lineLimit(1)
                    .frame(width: Self.formColumnWidth, alignment: .leading)
                Text(choice.names.joined(separator: "・"))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice.label)
        .accessibilityIdentifier("componentFormItem.\(row).\(choice.forms[0])")
    }

    // 高さ 0 の区切り: 線は項目の上端に重ね、画数のラベルは線の右端の下(その画数の最初の項目の右上)に置く
    private func strokeDivider(_ strokes: Int) -> some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.4))
            .frame(height: 0.5)
            .overlay(alignment: .topTrailing) {
                Text("\(strokes)画")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .padding(.top, 2)
                    .accessibilityIdentifier("componentFormStroke.\(row).\(strokes)")
            }
            .padding(.trailing, 12)
            .frame(height: 0, alignment: .top)
            .allowsHitTesting(false)
    }
}

// 位置名の左のアイコン(Kangxi タブのカテゴリーと同じ図形)
struct ComponentPositionIconView: View {
    let category: RadicalPositionCategory
    var color: Color = Theme.accent

    var body: some View {
        ZStack {
            RadicalPositionIcon(category: category)
                .fill(color)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color.opacity(0.6), lineWidth: 1)
                .padding(2)
        }
        .frame(width: 22, height: 22)
    }
}

// メニューの項目は Image しか描けないため、アイコンを画像にして持つ(位置ごとに 1 回だけ描く)。
// Image(decorative:) にすると項目全体がアクセシビリティから消えるので、ラベル付きで作る
@MainActor
enum ComponentPositionIconImage {
    private static var cache: [RadicalPositionCategory: Image] = [:]

    static func image(for category: RadicalPositionCategory) -> Image {
        if let image = cache[category] {
            return image
        }
        let renderer = ImageRenderer(content: ComponentPositionIconView(category: category, color: .black))
        renderer.scale = 3
        guard let cgImage = renderer.cgImage else {
            return Image(systemName: "square")
        }
        let image = Image(cgImage, scale: 3, label: Text(category.title)).renderingMode(.template)
        cache[category] = image
        return image
    }
}

#if os(iOS)
import UIKit

// 部品の入力欄。日本語キーボード(有効なら)で開く。SwiftUI の TextField はキーボードの言語を選べないため UITextField を包む
struct JapaneseTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let accessibilityIdentifier: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> JapaneseInputTextField {
        let field = JapaneseInputTextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = UIFont(name: Theme.minchoFontName, size: 20) ?? .preferredFont(forTextStyle: .body)
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done
        field.inputAccessoryView = KeyboardDismissal.accessoryToolbar()
        field.accessibilityIdentifier = accessibilityIdentifier
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: JapaneseInputTextField, context: Context) {
        context.coordinator.text = $text
        // 変換中(未確定の文字がある間)は書き戻さない
        if field.markedTextRange == nil, field.text != text {
            field.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func editingChanged(_ field: UITextField) {
            // 確定した文字だけで検索する
            guard field.markedTextRange == nil else {
                return
            }
            text.wrappedValue = field.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

final class JapaneseInputTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage?.hasPrefix("ja") == true } ?? super.textInputMode
    }
}

#elseif os(macOS)

struct JapaneseTextField: View {
    @Binding var text: String
    let placeholder: String
    let accessibilityIdentifier: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#endif
