import CorbeCore
import SwiftUI

// élément / corbé: [位置▼][部品テキスト] を 3 行。全行の AND で絞る。入力の変更で即時に検索し直す
struct ComponentSearchView: View {
    let library: KanjiLibrary
    let onCopy: (KanjiEntry) -> Void

    @State private var rows = Array(repeating: ComponentQueryRow(), count: 3)
    @State private var result: ComponentSearchResult?

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
                位置と部品(木 氵 など)を入れると、3 行すべてに当てはまる字を出します。\
                部首の形(木 日 寸 など)はそれ以上分けません。\
                にくづき は 月 で探します([偏 月] は 月 と にくづき を区別しません)。
                """,
                identifier: "emptyHint"
            )
        }
    }

    private func rowView(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Picker("位置", selection: $rows[index].position) {
                    ForEach(ComponentPosition.allCases) { position in
                        Text(position.title).tag(position)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(minWidth: 96, alignment: .leading)
                .accessibilityIdentifier("componentPosition.\(index)")
                JapaneseTextField(
                    text: $rows[index].text,
                    placeholder: "部品(例 木)",
                    accessibilityIdentifier: "componentText.\(index)"
                )
                .frame(height: 36)
            }
            if let result, result.rows[index] == .unusable {
                Text("部品として使えません")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .accessibilityIdentifier("componentRowStatus.\(index)")
            }
        }
    }

    private func search() {
        result = library.loaded?.componentSearch.search(rows)
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
