import SwiftUI

struct SettingsView: View {
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    @AppStorage("palette") private var paletteName = M3Palette.violet.rawValue
    @AppStorage(AppLanguage.storageKey) private var languageName = AppLanguage.english.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageName) ?? .english
    }

    private func t(_ english: String, _ russian: String) -> String {
        language.text(english, russian)
    }

    private var theme: M3Theme {
        M3Theme(
            palette: M3Palette(rawValue: paletteName) ?? .violet,
            scheme: colorScheme
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(theme.surfaceContainer)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.onSurface)
                .help(t("Back", "Назад"))

                VStack(alignment: .leading, spacing: 3) {
                    Text(t("Appearance", "Оформление"))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                    Text(t("Customize the look and feel", "Настройте внешний вид приложения"))
                        .font(.system(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 18)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle(t("Theme", "Тема"))
                        FloatingSegment(items: Appearance.allCases, selection: $appearance) { item in
                            Text(item.title(in: language))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle(t("Language", "Язык"))
                        FloatingSegment(items: AppLanguage.allCases, selection: $languageName) { item in
                            Text(item.title)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle(t("Material 3 Color Scheme", "Цветовая схема Material 3"))
                        FloatingPalettePicker(selection: $paletteName, language: language)
                    }

                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollIndicators(.never)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.m3, theme)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.onSurfaceVariant)
            .padding(.leading, 8)
    }

}
