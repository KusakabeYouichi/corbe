import CorbeCore
import SwiftUI

// 長押しで出す字典風の詳細(読み 音/訓・U+XXXX・区点・総画数・部首番号・常用/教育/人名用・JLPT)
struct KanjiDetailView: View {
    let entry: KanjiEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.character)
                .font(.custom(Theme.minchoFontName, size: 44))
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            row("音", value: entry.onReadings.isEmpty ? "—" : entry.onReadings.joined(separator: "、"), identifier: "detail.on")
            row("訓", value: entry.kunReadings.isEmpty ? "—" : entry.kunReadings.joined(separator: "、"), identifier: "detail.kun")
            row("符号", value: entry.codePointLabel, identifier: "detail.codePoint")
            row("区点", value: entry.kuten.isEmpty ? "—" : entry.kuten, identifier: "detail.kuten")
            row("総画数", value: entry.totalStrokes > 0 ? "\(entry.totalStrokes)画" : "—", identifier: "detail.totalStrokes")
            row("部首", value: "\(entry.radical)", identifier: "detail.radical")
            row("区分", value: Self.categoryText(entry), identifier: "detail.category", singleLine: true)
            row("JLPT", value: entry.jlptLevel.map { "N\($0)(非公式)" } ?? "—", identifier: "detail.jlpt")
        }
        .padding(16)
        .frame(minWidth: 220, idealWidth: 300, maxWidth: 340)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kanjiDetail")
    }

    // 『常用 ○  教育 ○(1年)  人名用 —』。人名用は常用漢字以外で名前に使える字(戸籍法施行規則 別表第二)なので、
    // 常用漢字には当てはまらない(—)。名前に使えるのは 常用 ○ か 人名用 ○ の字
    static func categoryText(_ entry: KanjiEntry) -> String {
        let mark: (Bool) -> String = { $0 ? "○" : "×" }
        let school = entry.schoolGrade.map { "○(\($0)年)" } ?? "×"
        let jinmeiyo = entry.isJoyo ? "—" : mark(entry.isJinmeiyo)
        return "常用 \(mark(entry.isJoyo))  教育 \(school)  人名用 \(jinmeiyo)"
    }

    // singleLine: 区分のように折り返すと読みにくい行は、小さい画面(吹き出しが狭い)では字を少し縮めて 1 行に収める
    private func row(_ title: String, value: String, identifier: String, singleLine: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            Text(value)
                .font(.callout)
                .lineLimit(singleLine ? 1 : nil)
                .minimumScaleFactor(singleLine ? 0.75 : 1)
                .fixedSize(horizontal: false, vertical: !singleLine)
                .textSelection(.enabled)
                .accessibilityIdentifier(identifier)
        }
    }
}
