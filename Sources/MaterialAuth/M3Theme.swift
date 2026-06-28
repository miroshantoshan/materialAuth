import SwiftUI

struct M3Theme {
    let palette: M3Palette
    let scheme: ColorScheme

    var primary: Color { palette.seed }
    var onPrimary: Color { .white }
    var primaryContainer: Color {
        scheme == .dark ? palette.seed.opacity(0.34) : palette.container
    }
    var onPrimaryContainer: Color {
        scheme == .dark ? palette.container : palette.seed
    }
    var surface: Color {
        scheme == .dark
            ? Color(red: 0.075, green: 0.07, blue: 0.085)
            : Color(red: 0.985, green: 0.98, blue: 0.99)
    }
    var surfaceContainer: Color {
        scheme == .dark
            ? Color(red: 0.13, green: 0.12, blue: 0.14)
            : Color(red: 0.95, green: 0.94, blue: 0.96)
    }
    var surfaceContainerHigh: Color {
        scheme == .dark
            ? Color(red: 0.18, green: 0.17, blue: 0.19)
            : Color(red: 0.91, green: 0.90, blue: 0.92)
    }
    var onSurface: Color {
        scheme == .dark ? Color(white: 0.93) : Color(white: 0.12)
    }
    var onSurfaceVariant: Color {
        scheme == .dark ? Color(white: 0.72) : Color(white: 0.34)
    }
    var outline: Color {
        scheme == .dark ? Color(white: 0.42) : Color(white: 0.53)
    }
}

private struct M3ThemeKey: EnvironmentKey {
    static let defaultValue = M3Theme(palette: .violet, scheme: .light)
}

extension EnvironmentValues {
    var m3: M3Theme {
        get { self[M3ThemeKey.self] }
        set { self[M3ThemeKey.self] = newValue }
    }
}

struct M3FilledButtonStyle: ButtonStyle {
    @Environment(\.m3) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(theme.onPrimary)
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(theme.primary.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct M3IconButtonStyle: ButtonStyle {
    @Environment(\.m3) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(theme.onSurfaceVariant)
            .frame(width: 40, height: 40)
            .background(configuration.isPressed ? theme.surfaceContainerHigh : .clear)
            .clipShape(Circle())
    }
}

struct M3TextFieldStyle: TextFieldStyle {
    @Environment(\.m3) private var theme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(.ultraThinMaterial)
            .background(theme.surfaceContainer.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
