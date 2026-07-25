import SwiftUI

@main
struct MaterialAuthApp: App {
    @StateObject private var store = AccountStore()
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    @AppStorage(AppLanguage.storageKey) private var languageName = AppLanguage.english.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageName) ?? .english
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
                .frame(
                    minWidth: 380,
                    idealWidth: 380,
                    maxWidth: 380,
                    minHeight: 520,
                    idealHeight: 550,
                    maxHeight: 760
                )
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(language.text("Add Account", "Добавить аккаунт")) {
                    NotificationCenter.default.post(name: .showAddAccount, object: nil)
                }
                .keyboardShortcut("n")
            }
        }
    }
}

extension Notification.Name {
    static let showAddAccount = Notification.Name("showAddAccount")
}
