import CorbeCore
import SwiftUI

// 位置名の左のアイコン(Kangxi タブのカテゴリーと同じ図形)
struct ComponentPositionIconView: View {
    let category: RadicalPositionCategory
    var color: Color = Theme.accent

    var body: some View {
        ZStack {
            RadicalPositionIcon(category: category)
                .fill(color)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color.opacity(0.6), lineWidth: 1)
                .padding(2)
        }
        .frame(width: 22, height: 22)
    }
}

// メニューの項目は Image しか描けないため、アイコンを画像にして持つ(位置ごとに 1 回だけ描く)。
// Image(decorative:) にすると項目全体がアクセシビリティから消えるので、ラベル付きで作る
@MainActor
enum ComponentPositionIconImage {
    private static var cache: [RadicalPositionCategory: Image] = [:]

    static func image(for category: RadicalPositionCategory) -> Image {
        if let image = cache[category] {
            return image
        }
        let renderer = ImageRenderer(content: ComponentPositionIconView(category: category, color: .black))
        renderer.scale = 3
        guard let cgImage = renderer.cgImage else {
            return Image(systemName: "square")
        }
        let image = Image(cgImage, scale: 3, label: Text(category.title)).renderingMode(.template)
        cache[category] = image
        return image
    }
}
