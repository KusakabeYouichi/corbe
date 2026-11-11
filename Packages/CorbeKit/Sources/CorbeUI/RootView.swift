import CorbeCore
import SwiftUI

// TabView 4 タブ: élément(corbé / Kangxi)と Lecture(chinoise / japonaise)。
// 結果の字をタップするとクリップボードへ入れ、画面下に『『村』をコピーしました』を出す
public struct RootView: View {
    enum Screen: Hashable {
        case corbe
        case kangxi
        case chinoise
        case japonaise
    }

    // 『コピーしました』を出しておく時間。UI テスト(corbeUITests)用に、起動引数 -corbeUITestBadgeSeconds <秒> で延ばせる
    private static var badgeDuration: Duration {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-corbeUITestBadgeSeconds"),
            arguments.indices.contains(index + 1),
            let seconds = Double(arguments[index + 1]), seconds > 0 {
            return .seconds(seconds)
        }
        #endif
        return .seconds(1.5)
    }

    @State private var library = KanjiLibrary()
    @State private var selection = Screen.corbe
    @State private var copiedCharacter: String?
    @State private var badgeHideTask: Task<Void, Never>?
    @State private var isShowingLicenses = false

    public init() {}

    public var body: some View {
        TabView(selection: $selection) {
            Tab("corbé", systemImage: "square.grid.3x3.square", value: Screen.corbe) {
                screen(section: "élément", title: "corbé") {
                    ComponentSearchView(library: library, onCopy: copy)
                }
            }
            Tab("Kangxi", systemImage: "square.split.2x2", value: Screen.kangxi) {
                screen(section: "élément", title: "Kangxi") {
                    KangxiPickerView(library: library, onCopy: copy)
                }
            }
            Tab("chinoise", systemImage: "character.book.closed", value: Screen.chinoise) {
                screen(section: "Lecture", title: "chinoise") {
                    ReadingSearchView(kind: .on, library: library, onCopy: copy)
                }
            }
            Tab("japonaise", systemImage: "text.book.closed", value: Screen.japonaise) {
                screen(section: "Lecture", title: "japonaise") {
                    ReadingSearchView(kind: .kun, library: library, onCopy: copy)
                }
            }
        }
        .tint(Theme.accent)
        .task {
            await library.load()
        }
        .sheet(isPresented: $isShowingLicenses) {
            LicensesView()
        }
    }

    private func screen(section: String, title: String, @ViewBuilder content: () -> some View) -> some View {
        NavigationStack {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Theme.paper)
                .overlay(alignment: .bottom) {
                    if let copiedCharacter {
                        CopiedBadge(character: copiedCharacter)
                            .padding(.bottom, 12)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(section)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(title)
                                .font(.headline)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("screenTitle")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isShowingLicenses = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("ライセンス")
                        .accessibilityIdentifier("licensesButton")
                    }
                }
        }
    }

    private func copy(_ entry: KanjiEntry) {
        SystemPasteboard.setString(entry.character)
        showCopiedBadge(entry.character)
    }

    // 表示は常に 1 枚。表示中に再び呼ばれたら字を差し替えて残り時間を数え直す
    private func showCopiedBadge(_ character: String) {
        badgeHideTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            copiedCharacter = character
        }
        AccessibilityNotification.Announcement(CopiedBadge.message(for: character)).post()
        badgeHideTask = Task {
            try? await Task.sleep(for: Self.badgeDuration)
            guard !Task.isCancelled else {
                return
            }
            withAnimation(.easeIn(duration: 0.3)) {
                copiedCharacter = nil
            }
        }
    }
}
