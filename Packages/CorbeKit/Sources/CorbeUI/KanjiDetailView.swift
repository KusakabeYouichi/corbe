import CorbeCore
import SwiftUI

// 長押しで出す字典風の詳細(読み 音/訓・U+XXXX・区点・総画数・部首番号)
struct KanjiDetailView: View {
    let entry: KanjiEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.character)
                .font(.custom(Theme.minchoFontName, size: 44))
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            row("音", value: entry.onReadings.isEmpty ? "—" : entry.onReadings.joined(separator: " "), identifier: "detail.on")
            row("訓", value: entry.kunReadings.isEmpty ? "—" : entry.kunReadings.joined(separator: " "), identifier: "detail.kun")
            row("符号", value: entry.codePointLabel, identifier: "detail.codePoint")
            row("区点", value: entry.kuten.isEmpty ? "—" : entry.kuten, identifier: "detail.kuten")
            row("総画数", value: entry.totalStrokes > 0 ? "\(entry.totalStrokes)画" : "—", identifier: "detail.totalStrokes")
            row("部首", value: "\(entry.radical)", identifier: "detail.radical")
        }
        .padding(16)
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kanjiDetail")
    }

    private func row(_ title: String, value: String, identifier: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            Text(value)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .accessibilityIdentifier(identifier)
        }
    }
}
