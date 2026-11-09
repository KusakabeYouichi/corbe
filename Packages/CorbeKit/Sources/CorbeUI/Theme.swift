import SwiftUI

// 画面の色。régu と同じく、アイコンの世界観(紙の白・墨・朱の点)に合わせ、ライト／ダークの組で持つ。
// 朱は文字にも使うため、カード地と背景の上で 4.5:1 以上になる値にしている
// (ロゴの朱。ライト #AD2533: 白 6.80 / 紙 6.19、ダーク #F0707E: カード 5.81 / 背景 6.53)
enum Theme {
    static let paper = Color(platformColor: dynamic(light: 0xF6F4F0, dark: 0x121212))
    static let card = Color(platformColor: dynamic(light: 0xFFFFFF, dark: 0x1E1E1E))
    static let accent = Color(platformColor: dynamic(light: 0xAD2533, dark: 0xF0707E))
    static let cardCornerRadius: CGFloat = 20
    // ヒラギノ明朝(字グリッドの字)
    static let minchoFontName = "HiraMinProN-W3"
    // ヒラギノ明朝にグリフが無い字(別フォントで描かれる)の色。écritu の字グリッドと同じ薄いブルー系
    static let fallbackGlyph = Color(platformColor: dynamic(light: 0x5285E0, dark: 0x94C2FF))
}

#if os(iOS)
import UIKit

extension Theme {
    static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

private extension Color {
    init(platformColor: UIColor) {
        self.init(uiColor: platformColor)
    }
}

#elseif os(macOS)
import AppKit

extension Theme {
    static func dynamic(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(rgb: isDark ? dark : light)
        }
    }
}

private extension NSColor {
    convenience init(rgb: UInt32) {
        self.init(
            srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

private extension Color {
    init(platformColor: NSColor) {
        self.init(nsColor: platformColor)
    }
}

#endif

// 入力欄・結果欄のカード。ライトはタイルのような柔らかい影、ダークは影なし
struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.07), radius: 10, y: 3)
            }
    }
}
