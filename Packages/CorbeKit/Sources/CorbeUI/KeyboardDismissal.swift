import SwiftUI

#if os(iOS)
import UIKit
#endif

// キーボードを閉じる(入力欄のフォーカスを外す)。iOS の一般的なアプリと同じく、
// キーボード上の『完了』・入力欄の外のタップ・結果のスクロールで閉じられるようにする
enum KeyboardDismissal {
    @MainActor
    static func dismiss() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    #if os(iOS)
    // UITextField のキーボードの上に出す『完了』の帯
    @MainActor
    static func accessoryToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        let done = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { _ in dismiss() })
        done.title = "完了"
        done.accessibilityIdentifier = "keyboardDone"
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace), done]
        toolbar.sizeToFit()
        return toolbar
    }
    #endif
}

// 指が触れた時点(離す前)に動くボタンの見た目。押している間は少し薄くする。
// 支援技術からの操作(VoiceOver のダブルタップなど)は Button の action で受ける
struct PressDownButtonStyle: ButtonStyle {
    let onPressDown: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    onPressDown()
                }
            }
    }
}
