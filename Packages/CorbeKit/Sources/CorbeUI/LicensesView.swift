import SwiftUI

// (i) から開くライセンス画面: corbé の著作権、Unicode License(Unihan / UCD)全文、BabelStone IDS の出典と作者の表明
struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss

    private static let unicodeLicense: String = {
        // 同梱漏れは開発時に気づくよう止める(ライセンス全文を欠いたまま出さない)
        guard let url = Bundle.module.url(forResource: "UNICODE-LICENSE", withExtension: "txt"),
            let text = try? String(contentsOf: url, encoding: .utf8) else {
            preconditionFailure("UNICODE-LICENSE.txt が CorbeUI に同梱されていません")
        }
        return text
    }()

    // バージョン(MARKETING_VERSION)とビルド番号(CURRENT_PROJECT_VERSION)。ビルド番号はバージョンと別に数える
    private static let versionText: String = {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (info?["CFBundleVersion"] as? String) ?? "?"
        return "バージョン \(version)(ビルド \(build))"
    }()

    private static let babelStoneStatement = """
    Therefore, anyone is free to make use of the IDS data provided in this file for personal or commercial \
    purposes without asking permission or providing attribution. I furthermore waive any copyright claims to the \
    presentation format of the IDS data used in this file, so anyone is free to fork the file, or use it as the \
    basis for a new IDS data set.
    """

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("corbé") {
                        Text(Self.versionText)
                            .accessibilityIdentifier("appVersion")
                        Text("Copyright © 2026 Kusakabe Youichi. All rights reserved.")
                        Text("第三者のデータは、それぞれのライセンスに従います(以下)。")
                    }
                    section("Unihan / Unicode Character Database") {
                        Text("部首・画数・区点・読み(Unihan 17.0.0)と部首の字(CJKRadicals.txt / EquivalentUnifiedIdeograph.txt)。Unicode License v3")
                        Text(Self.unicodeLicense)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                    section("BabelStone IDS") {
                        Text("部品の分解。Andrew West (魏安), https://www.babelstone.co.uk/CJK/IDS.TXT(Unicode 16.0 版, 2025-06-27)")
                        Text("作者はファイルの中で次のように表明しています:")
                        Text(Self.babelStoneStatement)
                            .font(.callout.italic())
                            .padding(.leading, 12)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("ライセンス")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                        .accessibilityIdentifier("licensesClose")
                }
            }
            .accessibilityIdentifier("licensesView")
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
                .font(.callout)
        }
    }
}
