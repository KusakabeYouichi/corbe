#if os(iOS)
import UIKit

// タップした字をクリップボードへ入れる(UIPasteboard.general)
enum SystemPasteboard {
    @MainActor
    static func setString(_ string: String) {
        UIPasteboard.general.string = string
    }
}

#elseif os(macOS)
import AppKit

// タップした字をクリップボードへ入れる(NSPasteboard.general)
enum SystemPasteboard {
    @MainActor
    static func setString(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}

#endif
