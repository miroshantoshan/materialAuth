import Combine
import Foundation

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var accounts: [OTPAccount] = []
    @Published var errorMessage: String?

    private let defaultsKey = "otpAccounts"

    init() {
        load()
    }

    func secret(for account: OTPAccount) -> String? {
        KeychainStore.read(for: account.id)
    }

    func add(account: OTPAccount, secret: String) {
        do {
            guard Base32.decode(secret) != nil else { throw TOTPError.invalidSecret }
            try KeychainStore.save(secret, for: account.id)
            accounts.append(account)
            accounts.sort { $0.issuer.localizedCaseInsensitiveCompare($1.issuer) == .orderedAscending }
            persist()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(uri: String) -> Bool {
        do {
            let payload = try OTPAuthPayload.parse(uri.trimmingCharacters(in: .whitespacesAndNewlines))
            add(account: payload.account, secret: payload.secret)
            return errorMessage == nil
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(_ account: OTPAccount) {
        KeychainStore.delete(for: account.id)
        accounts.removeAll { $0.id == account.id }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        do {
            accounts = try JSONDecoder().decode([OTPAccount].self, from: data)
        } catch {
            errorMessage = "Не удалось загрузить сохранённые аккаунты."
        }
    }

    private func persist() {
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(accounts), forKey: defaultsKey)
        } catch {
            errorMessage = "Не удалось сохранить список аккаунтов."
        }
    }
}
