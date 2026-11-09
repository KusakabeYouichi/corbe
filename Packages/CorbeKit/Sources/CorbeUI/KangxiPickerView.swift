import CorbeCore
import SwiftUI

// élément / Kangxi: 位置カテゴリー 8 種 → 部首字形の一覧(画数の区切り付き) → 字グリッド(総画数の区切り付き)。
// écritu の部首ピッカー(KeyboardRootView+KanjiRadicalLayout)の流れを流用。部首の画数は既定(選択肢の先頭)で固定
struct KangxiPickerView: View {
    let library: KanjiLibrary
    let onCopy: (KanjiEntry) -> Void

    @State private var pickerState = RadicalPickerState()

    private static let radicalColumns = [GridItem(.adaptive(minimum: 54, maximum: 72), spacing: 6)]

    var body: some View {
        VStack(spacing: 8) {
            categoryBar
            if let loaded = library.loaded {
                if let form = pickerState.selectedForm {
                    characterGrid(for: form, loaded: loaded)
                } else {
                    radicalList(loaded: loaded)
                }
            } else {
                SearchStatusView.notLoaded(error: library.loadError)
            }
        }
        .padding(.top, 8)
    }

    private var categoryBar: some View {
        HStack(spacing: 4) {
            ForEach(RadicalPositionCategory.allCases) { category in
                let isSelected = pickerState.selectedCategory == category
                Button {
                    pickerState.selectCategory(category)
                } label: {
                    VStack(spacing: 2) {
                        RadicalPositionIcon(category: category)
                            .fill(isSelected ? Theme.accent : Color.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.6), lineWidth: 1)
                                    .padding(3)
                            )
                            .frame(width: 26, height: 26)
                        Text(category.title)
                            .font(.caption2)
                            .foregroundStyle(isSelected ? Theme.accent : Color.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? Theme.card : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(category.accessibilityLabel)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("radicalCategory.\(category.rawValue)")
            }
        }
        .padding(.horizontal, 12)
    }

    private func radicalList(loaded: KanjiLibrary.Loaded) -> some View {
        let items = StrokeListing.radicalListItems(forms: loaded.catalog.forms(in: pickerState.selectedCategory))
        return VStack(spacing: 4) {
            SearchStatusView(text: "位置を選び、部首を選んでください(部首の画数で並んでいます)", identifier: "emptyHint", isCompact: true)
            ScrollView {
                LazyVGrid(columns: Self.radicalColumns, spacing: 6) {
                    ForEach(items, id: \.id) { item in
                        switch item.kind {
                        case .strokeMarker(let strokes):
                            Text("\(strokes)画")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.primary.opacity(0.75))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.secondary.opacity(0.12))
                                )
                                .accessibilityLabel("\(strokes)画の部首")
                                .accessibilityIdentifier("radicalStrokeMarker.\(strokes)")
                        case .form(let form):
                            radicalButton(form)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
    }

    private func radicalButton(_ form: RadicalForm) -> some View {
        Button {
            pickerState.selectForm(form)
        } label: {
            VStack(spacing: 0) {
                Text(form.displayForm)
                    .font(.custom(Theme.minchoFontName, size: 24))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(form.name)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.card)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(form.displayForm) \(form.name)")
        .accessibilityIdentifier("radicalForm.\(form.id)")
    }

    private func characterGrid(for form: RadicalForm, loaded: KanjiLibrary.Loaded) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Button {
                    pickerState.clearForm()
                } label: {
                    Label(pickerState.selectedCategory.title, systemImage: "chevron.backward")
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("radicalBack")
                Text("› \(form.displayForm)(\(form.name))")
                    .font(.headline)
                    .accessibilityIdentifier("radicalTitle")
                Spacer()
            }
            .padding(.horizontal, 12)
            KanjiResultGrid(
                items: StrokeListing.characterListItems(entries: loaded.index.entries(forRadical: form.radical)),
                onCopy: onCopy
            )
            .id(form.id)
        }
    }
}
