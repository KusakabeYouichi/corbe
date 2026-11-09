import Foundation

// 字グリッドに挟む総画数の区切り(タップ不可)。écritu の RadicalPickerListing から流用
public enum KanjiListItem: Sendable, Equatable {
    case totalStrokeMarker(Int)
    case character(KanjiEntry)
}

// 部首一覧に挟む画数の区切り(タップ不可)。部首を探す手掛かりは画数のため
public enum RadicalListItem: Sendable, Equatable {
    case strokeMarker(Int)
    case form(RadicalForm)
}

// 一覧の組み立て規則(表示から切り離した純関数)
public enum StrokeListing {
    // 総画数が変わる位置に区切りを入れる。総画数 0(kTotalStrokes の無い字)には区切りを出さない。
    // 並べ替えはしない(呼ぶ側が総画数順に並べて渡す)
    public static func characterListItems(entries: [KanjiEntry]) -> [(id: String, kind: KanjiListItem)] {
        var items: [(id: String, kind: KanjiListItem)] = []
        var lastTotal = -1
        for entry in entries {
            let total = entry.totalStrokes
            if total > 0, total != lastTotal {
                items.append((id: "total-\(total)", kind: .totalStrokeMarker(total)))
                lastTotal = total
            }
            items.append((id: "char-\(entry.character)", kind: .character(entry)))
        }
        return items
    }

    public static func radicalListItems(forms: [RadicalForm]) -> [(id: String, kind: RadicalListItem)] {
        var items: [(id: String, kind: RadicalListItem)] = []
        var lastStrokes = -1
        for form in forms {
            let strokes = form.listStrokes
            if strokes != lastStrokes {
                items.append((id: "marker-\(strokes)", kind: .strokeMarker(strokes)))
                lastStrokes = strokes
            }
            items.append((id: form.id, kind: .form(form)))
        }
        return items
    }
}
