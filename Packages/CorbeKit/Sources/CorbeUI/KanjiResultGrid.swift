import CorbeCore
import CoreText
import SwiftUI

// 4 つのタブで共通の字グリッド(écritu の字グリッドの流用。アプリなので UICollectionView ではなく LazyVGrid)。
// 総画数の区切り(タップ不可)を挟み、タップ = コピー、0.35 秒の長押し = 詳細(コピーしない)。
// ヒラギノ明朝にグリフが無い字は色を変える(écritu と同じ判定・配色)
struct KanjiResultGrid: View {
    let items: [(id: String, kind: KanjiListItem)]
    let onCopy: (KanjiEntry) -> Void

    @State private var detailEntry: KanjiEntry?

    private static let columns = [GridItem(.adaptive(minimum: 46, maximum: 64), spacing: 6)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Self.columns, spacing: 6) {
                ForEach(items, id: \.id) { item in
                    switch item.kind {
                    case .totalStrokeMarker(let total):
                        TotalStrokeMarker(total: total)
                    case .character(let entry):
                        cell(for: entry)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func cell(for entry: KanjiEntry) -> some View {
        Text(entry.character)
            .font(.custom(Theme.minchoFontName, size: 28))
            .foregroundStyle(KanjiGlyphAvailability.hasMinchoGlyph(for: entry.character) ? Color.primary : Theme.fallbackGlyph)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.card)
            )
            .contentShape(Rectangle())
            // 長押しが成立したら詳細だけを出し、タップ(コピー)は起こさない
            .gesture(
                LongPressGesture(minimumDuration: 0.35)
                    .onEnded { _ in detailEntry = entry }
                    .exclusively(before: TapGesture().onEnded { onCopy(entry) })
            )
            .popover(isPresented: detailBinding(for: entry)) {
                KanjiDetailView(entry: entry)
                    .presentationCompactAdaptation(.popover)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.character)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("kanji.\(entry.character)")
            .accessibilityAction(named: "詳細") { detailEntry = entry }
    }

    private func detailBinding(for entry: KanjiEntry) -> Binding<Bool> {
        Binding(
            get: { detailEntry?.id == entry.id },
            set: { isPresented in
                if !isPresented {
                    detailEntry = nil
                }
            }
        )
    }
}

// 総画数の区切り(タップできない)。カプセル+輪郭線+『総N画』
private struct TotalStrokeMarker: View {
    let total: Int

    var body: some View {
        Text("総\(total)画")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.primary.opacity(0.7))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                    .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1))
                    .padding(.vertical, 12)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("総画数\(total)画")
            .accessibilityIdentifier("strokeMarker.\(total)")
    }
}

// 字形の有無(écritu の KanjiGlyphAvailability と同じ判定)。表示中のセルぶんだけ
// 『ヒラギノ明朝にグリフがあるか』を確かめる。無い字は別フォントで描かれるため色を変えて区別する
@MainActor
enum KanjiGlyphAvailability {
    private static let mincho = CTFontCreateWithName(Theme.minchoFontName as CFString, 16, nil)

    static func hasMinchoGlyph(for character: String) -> Bool {
        guard !character.isEmpty else {
            return false
        }
        var chars = Array(character.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        guard CTFontGetGlyphsForCharacters(mincho, &chars, &glyphs, chars.count) else {
            return false
        }
        return glyphs.allSatisfy { $0 != 0 }
    }
}
