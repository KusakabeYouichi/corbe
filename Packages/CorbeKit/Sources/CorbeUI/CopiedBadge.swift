import SwiftUI

// 「✓「村」をコピーしました」の小さなカプセル(régu の CopiedBadge と同じ見た目)。表示・消去の時間は RootView が受け持つ
struct CopiedBadge: View {
    let character: String

    var body: some View {
        Label("「\(character)」をコピーしました", systemImage: "checkmark")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .lineLimit(1)
            // 画面の下に重ねる小さな表示なので、文字の拡大は大きめの通常サイズまでに留める
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(Theme.card)
                    .overlay {
                        Capsule().strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1)
                    }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("「\(character)」をコピーしました")
            .accessibilityIdentifier("copiedBadge")
    }
}
