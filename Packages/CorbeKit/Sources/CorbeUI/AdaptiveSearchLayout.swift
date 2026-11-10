import SwiftUI

// 縦長は入力の下に結果、横長(幅 > 高さ)は左に入力・右に結果。
// 結果の側は、空いた所のタップとスクロールでキーボードを閉じる(字のタップはコピーとして働き、キーボードも閉じる)
struct AdaptiveSearchLayout<Input: View, Results: View>: View {
    @ViewBuilder let input: Input
    @ViewBuilder let results: Results

    init(@ViewBuilder input: () -> Input, @ViewBuilder results: () -> Results) {
        self.input = input()
        self.results = results()
    }

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > proxy.size.height {
                HStack(alignment: .top, spacing: 12) {
                    ScrollView {
                        input
                            .padding(.leading, 12)
                            .padding(.vertical, 8)
                    }
                    .frame(width: min(380, proxy.size.width * 0.45))
                    .scrollDismissesKeyboard(.interactively)
                    VStack(spacing: 0) {
                        results
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .modifier(DismissesKeyboard())
                }
            } else {
                VStack(spacing: 8) {
                    input
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    results
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .modifier(DismissesKeyboard())
                }
            }
        }
    }
}

// 結果の側でキーボードを閉じる: スクロールし始めたら閉じ、空いた所のタップでも閉じる。
// タップは字のボタンと同時に受ける(字のタップを奪わない)
private struct DismissesKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.immediately)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { KeyboardDismissal.dismiss() })
    }
}
