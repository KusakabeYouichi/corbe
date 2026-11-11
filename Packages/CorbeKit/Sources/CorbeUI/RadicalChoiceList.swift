import CorbeCore
import SwiftUI

// 部首の一覧(吹き出しの中身)。先頭は未選択に戻す Aucun、続いて 字形(明朝・列幅を固定)と 読み。
// 画数の区切りは項目の上端に重ねた線で描き、行の高さを取らない。画数は線の右端の下に小さく書く(どの画数の始まりか分かるように)
struct RadicalChoiceList: View {
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

    // 未選択に戻す項目。部首と見分けるため斜体にし、色はボタンの未選択表示(『選択』)と同じ secondary にする
    private var noneItem: some View {
        rowButton(selecting: nil) {
            Text("Aucun")
                .italic()
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("componentFormNone.\(row)")
    }

    private func item(_ choice: ComponentRadicalChoice) -> some View {
        rowButton(selecting: choice) {
            Text(choice.forms.joined(separator: " "))
                .font(.custom(Theme.minchoFontName, size: 22))
                .lineLimit(1)
                .frame(width: Self.formColumnWidth, alignment: .leading)
            Text(choice.names.joined(separator: "・"))
                .lineLimit(1)
        }
        .accessibilityLabel(choice.label)
        .accessibilityIdentifier("componentFormItem.\(row).\(choice.forms[0])")
    }

    // 一覧の 1 行(幅いっぱいが当たり判定)。中身は左詰めで並べる
    private func rowButton(selecting choice: ComponentRadicalChoice?, @ViewBuilder content: () -> some View) -> some View {
        Button {
            onSelect(choice)
        } label: {
            HStack(spacing: 0) {
                content()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: Self.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
