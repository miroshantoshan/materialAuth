import SwiftUI

struct FloatingIsland<Content: View>: View {
    @Environment(\.m3) private var theme
    let padding: CGFloat
    @ViewBuilder let content: Content

    init(padding: CGFloat = 6, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .background(theme.surfaceContainer.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            .shadow(color: .black.opacity(0.10), radius: 18, y: 8)
    }
}

struct FloatingSegment<Item: Identifiable, Label: View>: View where Item.ID: Hashable {
    let items: [Item]
    @Binding var selection: Item.ID
    let label: (Item) -> Label
    @Environment(\.m3) private var theme

    var body: some View {
        FloatingIsland(padding: 5) {
            GeometryReader { geometry in
                let spacing: CGFloat = 4
                let width = (geometry.size.width - spacing * CGFloat(max(items.count - 1, 0))) / CGFloat(max(items.count, 1))
                let selectedIndex = items.firstIndex { $0.id == selection } ?? 0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.primaryContainer)
                        .frame(width: width, height: 42)
                        .shadow(color: theme.primary.opacity(0.18), radius: 10, y: 4)
                        .offset(x: CGFloat(selectedIndex) * (width + spacing))
                        .animation(.spring(response: 0.55, dampingFraction: 0.78), value: selectedIndex)

                    HStack(spacing: spacing) {
                        ForEach(items) { item in
                            Button {
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                                    selection = item.id
                                }
                            } label: {
                                label(item)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(selection == item.id ? theme.onPrimaryContainer : theme.onSurfaceVariant)
                                    .frame(width: width, height: 42)
                                    .contentShape(Capsule())
                                    .animation(.easeInOut(duration: 0.2), value: selection)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: 42)
        }
    }
}

struct FloatingPalettePicker: View {
    @Binding var selection: String
    @Environment(\.m3) private var theme

    private let palettes = M3Palette.allCases

    var body: some View {
        FloatingIsland(padding: 5) {
            GeometryReader { geometry in
                let spacing: CGFloat = 4
                let width = (geometry.size.width - spacing * CGFloat(palettes.count - 1)) / CGFloat(palettes.count)
                let selectedIndex = palettes.firstIndex { $0.rawValue == selection } ?? 0

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .fill(theme.primaryContainer)
                        .frame(width: width, height: 78)
                        .shadow(color: theme.primary.opacity(0.18), radius: 10, y: 4)
                        .offset(x: CGFloat(selectedIndex) * (width + spacing))
                        .animation(.spring(response: 0.58, dampingFraction: 0.76), value: selectedIndex)

                    HStack(spacing: spacing) {
                        ForEach(palettes) { palette in
                            Button {
                                withAnimation(.spring(response: 0.58, dampingFraction: 0.76)) {
                                    selection = palette.rawValue
                                }
                            } label: {
                                VStack(spacing: 7) {
                                    ZStack {
                                        Circle()
                                            .fill(palette.container)
                                            .frame(width: 42, height: 42)
                                        Circle()
                                            .fill(palette.seed)
                                            .frame(width: 23, height: 23)
                                        if selection == palette.rawValue {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .black))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    Text(palette.title)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(
                                            selection == palette.rawValue
                                                ? theme.onPrimaryContainer
                                                : theme.onSurfaceVariant
                                        )
                                        .lineLimit(1)
                                }
                                .frame(width: width, height: 78)
                                .contentShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: 78)
        }
    }
}

struct AmbientBackground: View {
    @Environment(\.m3) private var theme

    var body: some View {
        theme.surface.ignoresSafeArea()
    }
}

struct ServiceLogo: View {
    let issuer: String

    private var service: ServiceIdentity {
        ServiceIdentity(issuer: issuer)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(service.background)

            switch service.kind {
            case .microsoft:
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        square(.red)
                        square(.green)
                    }
                    HStack(spacing: 2) {
                        square(.blue)
                        square(.orange)
                    }
                }
            case .google:
                Text("G")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
            default:
                Image(systemName: service.symbol)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(service.foreground)
            }
        }
        .frame(width: 50, height: 50)
        .shadow(color: service.background.opacity(0.22), radius: 8, y: 4)
        .accessibilityLabel(issuer)
    }

    private func square(_ color: Color) -> some View {
        Rectangle().fill(color).frame(width: 10, height: 10)
    }
}

private struct ServiceIdentity {
    enum Kind {
        case generic, google, microsoft
    }

    let kind: Kind
    let symbol: String
    let foreground: Color
    let background: Color

    init(issuer: String) {
        let value = issuer.lowercased()
        if value.contains("google") || value.contains("gmail") {
            kind = .google
            symbol = "g.circle.fill"
            foreground = .blue
            background = .white
        } else if value.contains("microsoft") || value.contains("outlook") || value.contains("azure") {
            kind = .microsoft
            symbol = "square.grid.2x2.fill"
            foreground = .white
            background = Color(white: 0.96)
        } else if value.contains("github") {
            kind = .generic
            symbol = "chevron.left.forwardslash.chevron.right"
            foreground = .white
            background = Color(white: 0.08)
        } else if value.contains("apple") || value.contains("icloud") {
            kind = .generic
            symbol = "apple.logo"
            foreground = .white
            background = .black
        } else if value.contains("discord") {
            kind = .generic
            symbol = "bubble.left.and.bubble.right.fill"
            foreground = .white
            background = Color(red: 0.35, green: 0.40, blue: 0.95)
        } else if value.contains("telegram") {
            kind = .generic
            symbol = "paperplane.fill"
            foreground = .white
            background = Color(red: 0.16, green: 0.64, blue: 0.88)
        } else if value.contains("amazon") || value.contains("aws") {
            kind = .generic
            symbol = "shippingbox.fill"
            foreground = Color(red: 1, green: 0.66, blue: 0.16)
            background = Color(red: 0.10, green: 0.17, blue: 0.24)
        } else if value.contains("steam") {
            kind = .generic
            symbol = "gamecontroller.fill"
            foreground = .white
            background = Color(red: 0.08, green: 0.22, blue: 0.34)
        } else if value.contains("facebook") || value.contains("meta") {
            kind = .generic
            symbol = "person.2.fill"
            foreground = .white
            background = Color(red: 0.10, green: 0.43, blue: 0.86)
        } else {
            kind = .generic
            symbol = "key.fill"
            foreground = .white
            background = Color(red: 0.40, green: 0.31, blue: 0.64)
        }
    }
}
