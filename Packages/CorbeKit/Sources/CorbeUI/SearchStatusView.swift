import SwiftUI

// 結果欄の代わりに出す文(読み込み中・空状態のヒント・該当なし)
struct SearchStatusView: View {
    let text: String
    let identifier: String
    var isCompact = false
    var showsProgress = false

    // 索引の読み込み中。読み込みに失敗したら(同梱の資源の破損など)その旨を出し、読み込み中のままにしない
    static func notLoaded(error: String?) -> SearchStatusView {
        guard let error else {
            return SearchStatusView(text: "読み込み中", identifier: "loadingIndicator", showsProgress: true)
        }
        return SearchStatusView(text: "索引を読み込めませんでした(\(error))", identifier: "loadError")
    }

    static var noResults: SearchStatusView {
        SearchStatusView(text: "当てはまる字がありません", identifier: "noResults")
    }

    var body: some View {
        VStack(spacing: 8) {
            if showsProgress {
                ProgressView()
            }
            Text(text)
                .font(isCompact ? .footnote : .callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, isCompact ? 4 : 16)
        .frame(maxWidth: .infinity, alignment: showsProgress ? .center : .leading)
    }
}
