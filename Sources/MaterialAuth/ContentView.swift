import AppKit
import SwiftUI

struct ContentView: View {
    private enum Screen: Hashable {
        case accounts
        case addAccount
        case settings
    }

    @EnvironmentObject private var store: AccountStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("palette") private var paletteName = M3Palette.violet.rawValue
    @State private var search = ""
    @State private var screen = Screen.accounts
    @State private var copiedID: UUID?
    @State private var pageVisible = true
    @State private var isNavigating = false

    private var palette: M3Palette {
        M3Palette(rawValue: paletteName) ?? .violet
    }

    private var theme: M3Theme {
        M3Theme(palette: palette, scheme: colorScheme)
    }

    private var filteredAccounts: [OTPAccount] {
        guard !search.isEmpty else { return store.accounts }
        return store.accounts.filter {
            $0.issuer.localizedCaseInsensitiveContains(search)
                || $0.name.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            Group {
                switch screen {
                case .accounts:
                    VStack(spacing: 0) {
                        header

                        if store.accounts.isEmpty {
                            emptyState
                        } else {
                            accountList
                        }
                    }
                case .addAccount:
                    AddAccountView {
                        navigate(to: .accounts)
                    }
                case .settings:
                    SettingsView {
                        navigate(to: .accounts)
                    }
                }
            }
            .opacity(pageVisible ? 1 : 0)
            .scaleEffect(pageVisible ? 1 : 0.975)
            .offset(y: pageVisible ? 0 : 6)
            .blur(radius: pageVisible ? 0 : 4)
        }
        .clipped()
        .background(WindowHeightController(height: windowHeight))
        .environment(\.m3, theme)
        .alert("Что-то пошло не так", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("Понятно") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddAccount)) { _ in
            navigate(to: .addAccount)
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Коды")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.onSurface)
                    Text("\(store.accounts.count) \(accountWord(store.accounts.count))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.onSurfaceVariant)
                }

                Spacer()

                Button {
                    navigate(to: .settings)
                } label: {
                    Image(systemName: "paintpalette")
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(M3IconButtonStyle())
                .help("Оформление")

                Button {
                    navigate(to: .addAccount)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(M3IconButtonStyle())
                .help("Добавить аккаунт")
            }

            if !store.accounts.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.onSurfaceVariant)
                    TextField("Поиск", text: $search)
                        .textFieldStyle(.plain)
                    if !search.isEmpty {
                        Button {
                            search = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.onSurfaceVariant)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(theme.surfaceContainer)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    private var accountList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredAccounts) { account in
                    OTPCard(account: account, copied: copiedID == account.id) {
                        copyCode(for: account)
                    } onDelete: {
                        store.delete(account)
                    }
                }

                if filteredAccounts.isEmpty {
                    Text("Ничего не найдено")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .padding(.top, 48)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.primaryContainer)
                    .frame(width: 108, height: 108)
                Image(systemName: "lock.shield")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(theme.onPrimaryContainer)
            }

            VStack(spacing: 7) {
                Text("Здесь будут ваши коды")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.onSurface)
                Text("Добавьте секретный ключ или вставьте\nссылку формата otpauth://")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.onSurfaceVariant)
                    .lineSpacing(3)
            }

            Button("Добавить аккаунт") {
                navigate(to: .addAccount)
            }
            .buttonStyle(M3FilledButtonStyle())

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func copyCode(for account: OTPAccount) {
        guard let secret = store.secret(for: account),
              let code = try? TOTP.code(
                secret: secret,
                digits: account.digits,
                period: account.period,
                algorithm: account.algorithm
              )
        else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        copiedID = account.id

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if copiedID == account.id { copiedID = nil }
        }
    }

    private func accountWord(_ count: Int) -> String {
        count == 1 ? "аккаунт" : "аккаунтов"
    }

    private var windowHeight: CGFloat {
        switch screen {
        case .accounts: 550
        case .addAccount: 700
        case .settings: 620
        }
    }

    private func navigate(to destination: Screen) {
        guard destination != screen, !isNavigating else { return }
        isNavigating = true

        withAnimation(.easeInOut(duration: 0.14)) {
            pageVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(145))
            screen = destination
            withAnimation(.spring(response: 0.44, dampingFraction: 0.88, blendDuration: 0.08)) {
                pageVisible = true
            }
            try? await Task.sleep(for: .milliseconds(400))
            isNavigating = false
        }
    }
}

private struct WindowHeightController: NSViewRepresentable {
    let height: CGFloat

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            let frame = window.frame
            guard abs(frame.height - height) > 1 else { return }

            window.setFrame(
                NSRect(
                    x: frame.minX,
                    y: frame.maxY - height,
                    width: frame.width,
                    height: height
                ),
                display: true,
                animate: true
            )
        }
    }
}

private struct OTPCard: View {
    let account: OTPAccount
    let copied: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject private var store: AccountStore
    @Environment(\.m3) private var theme
    @State private var now = Date()
    @State private var hovering = false

    private var code: String {
        guard let secret = store.secret(for: account) else { return "••• •••" }
        let raw = (try? TOTP.code(
            secret: secret,
            date: now,
            digits: account.digits,
            period: account.period,
            algorithm: account.algorithm
        )) ?? "------"
        guard raw.count == 6 else { return raw }
        return "\(raw.prefix(3)) \(raw.suffix(3))"
    }

    private var remaining: Int {
        TOTP.remaining(period: account.period, date: now)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 14) {
                ServiceLogo(issuer: account.issuer)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(account.issuer)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.onSurface)
                            .lineLimit(1)
                        Text(account.name)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.onSurfaceVariant)
                            .lineLimit(1)
                    }

                    Text(currentCode(at: context.date))
                        .font(.system(size: 27, weight: .medium, design: .rounded).monospacedDigit())
                        .tracking(1.4)
                        .foregroundStyle(theme.onSurface)
                }

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(
                            remaining(at: context.date) <= 5
                                ? Color.orange.opacity(0.18)
                                : theme.primaryContainer
                        )
                    Text("\(remaining(at: context.date))")
                        .font(.system(size: 11, weight: .bold).monospacedDigit())
                        .foregroundStyle(
                            remaining(at: context.date) <= 5
                                ? Color.orange
                                : theme.onPrimaryContainer
                        )
                }
                .frame(width: 38, height: 38)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .background((hovering ? theme.surfaceContainerHigh : theme.surfaceContainer).opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            .shadow(color: .black.opacity(hovering ? 0.12 : 0.07), radius: hovering ? 16 : 10, y: 6)
            .contentShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            .scaleEffect(hovering ? 1.008 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: hovering)
            .overlay(alignment: .topTrailing) {
                if copied {
                    Text("Скопировано")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.onPrimaryContainer)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.primaryContainer)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
            .onTapGesture(perform: onCopy)
            .onHover { hovering = $0 }
            .contextMenu {
                Button("Скопировать код", action: onCopy)
                Divider()
                Button("Удалить", role: .destructive, action: onDelete)
            }
            .help("Нажмите, чтобы скопировать")
        }
    }

    private func currentCode(at date: Date) -> String {
        guard let secret = store.secret(for: account) else { return "••• •••" }
        let raw = (try? TOTP.code(
            secret: secret,
            date: date,
            digits: account.digits,
            period: account.period,
            algorithm: account.algorithm
        )) ?? "------"
        guard raw.count == 6 else { return raw }
        return "\(raw.prefix(3)) \(raw.suffix(3))"
    }

    private func remaining(at date: Date) -> Int {
        TOTP.remaining(period: account.period, date: date)
    }

}
