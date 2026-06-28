import SwiftUI

struct AddAccountView: View {
    let onBack: () -> Void

    enum Mode: String, CaseIterable, Identifiable {
        case qr
        case link
        case manual

        var id: String { rawValue }

        var title: String {
            switch self {
            case .qr: "QR-код"
            case .link: "Ссылка"
            case .manual: "Вручную"
            }
        }

        var symbol: String {
            switch self {
            case .qr: "qrcode.viewfinder"
            case .link: "link"
            case .manual: "keyboard"
            }
        }
    }

    @EnvironmentObject private var store: AccountStore
    @Environment(\.m3) private var theme
    @State private var modeID = Mode.qr.rawValue
    @State private var uri = ""
    @State private var issuer = ""
    @State private var accountName = ""
    @State private var secret = ""
    @State private var algorithm = OTPAlgorithm.sha1
    @State private var digits = 6
    @State private var isReadingQR = false

    private var mode: Mode {
        Mode(rawValue: modeID) ?? .qr
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                pageHeader

                FloatingSegment(items: Mode.allCases, selection: $modeID) { item in
                    Text(item.title)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Group {
                switch mode {
                case .qr:
                    qrContent
                case .link:
                    linkContent
                case .manual:
                    manualContent
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button("Отмена", action: onBack)
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 14)

                Button("Добавить", action: add)
                    .buttonStyle(M3FilledButtonStyle())
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.45)
            }
            .opacity(mode == .qr ? 0 : 1)
            .allowsHitTesting(mode != .qr)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .animation(.easeInOut(duration: 0.18), value: modeID)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var pageHeader: some View {
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
            .help("Назад")

            VStack(alignment: .leading, spacing: 4) {
                Text("Новый аккаунт")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.onSurface)
                Text("Секрет останется в Keychain этого Mac")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onSurfaceVariant)
            }
            Spacer()
        }
    }

    private var qrContent: some View {
        FloatingIsland(padding: 10) {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .fill(theme.primaryContainer)
                        .frame(width: 144, height: 144)

                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 66, weight: .light))
                        .foregroundStyle(theme.onPrimaryContainer)
                        .symbolEffect(.pulse, options: .repeating, isActive: isReadingQR)
                }

                VStack(spacing: 6) {
                    Text("Импорт из QR-кода")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.onSurface)
                    Text("Выберите скриншот или изображение QR-кода,\nкоторый показал сервис при настройке 2FA.")
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineSpacing(3)
                }

                Button {
                    importQR()
                } label: {
                    Label("Выбрать изображение", systemImage: "photo.badge.plus")
                }
                .buttonStyle(M3FilledButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 18)
        }
    }

    private var linkContent: some View {
        FloatingIsland(padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("Ссылка otpauth")
                TextField("otpauth://totp/…", text: $uri)
                    .textFieldStyle(M3TextFieldStyle())
                Text("Скопируйте полную ссылку из сервиса.")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .padding(.leading, 6)
            }
        }
    }

    private var manualContent: some View {
        FloatingIsland(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Сервис")
                    TextField("Например, GitHub", text: $issuer)
                        .textFieldStyle(M3TextFieldStyle())
                }
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Имя аккаунта")
                    TextField("name@example.com", text: $accountName)
                        .textFieldStyle(M3TextFieldStyle())
                }
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Секретный ключ")
                    SecureField("JBSWY3DPEHPK3PXP", text: $secret)
                        .textFieldStyle(M3TextFieldStyle())
                }

                HStack(spacing: 12) {
                    compactPicker("Алгоритм", selection: $algorithm) {
                        ForEach(OTPAlgorithm.allCases) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    compactPicker("Цифр", selection: $digits) {
                        Text("6").tag(6)
                        Text("8").tag(8)
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        if mode == .link {
            return uri.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("otpauth://")
        }
        return !issuer.trimmingCharacters(in: .whitespaces).isEmpty
            && !accountName.trimmingCharacters(in: .whitespaces).isEmpty
            && Base32.decode(secret) != nil
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.onSurfaceVariant)
            .padding(.leading, 6)
    }

    private func compactPicker<Value: Hashable, Content: View>(
        _ title: String,
        selection: Binding<Value>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Picker(title, selection: selection, content: content)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(theme.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
    }

    private func importQR() {
        isReadingQR = true
        defer { isReadingQR = false }

        do {
            guard let value = try QRCodeImporter.chooseAndRead() else { return }
            if store.add(uri: value) {
                onBack()
            }
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }

    private func add() {
        if mode == .link {
            if store.add(uri: uri) {
                onBack()
            }
        } else {
            store.add(
                account: OTPAccount(
                    issuer: issuer.trimmingCharacters(in: .whitespacesAndNewlines),
                    name: accountName.trimmingCharacters(in: .whitespacesAndNewlines),
                    digits: digits,
                    algorithm: algorithm
                ),
                secret: secret
            )
            if store.errorMessage == nil {
                onBack()
            }
        }
    }
}
