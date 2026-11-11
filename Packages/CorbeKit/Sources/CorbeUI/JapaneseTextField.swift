import SwiftUI

// 部品・読みの入力欄。日本語キーボード(有効なら)で開く。SwiftUI の TextField はキーボードの言語を選べないため UITextField を包む
#if os(iOS)
import UIKit

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
