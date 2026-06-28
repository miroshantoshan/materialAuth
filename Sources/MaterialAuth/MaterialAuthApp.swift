import SwiftUI

@main
struct MaterialAuthApp: App {
    @StateObject private var store = AccountStore()
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue

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
                Button("Добавить аккаунт") {
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
