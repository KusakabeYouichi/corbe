import SwiftUI

// 縦長は入力の下に結果、横長(幅 > 高さ)は左に入力・右に結果
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
                }
            } else {
                VStack(spacing: 8) {
                    input
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    results
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
    }
}
