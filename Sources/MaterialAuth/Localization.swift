import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case russian

    static let storageKey = "language"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: "English"
        case .russian: "Русский"
        }
    }

    static var current: AppLanguage {
        guard let value = UserDefaults.standard.string(forKey: storageKey) else {
            return .english
        }
        return AppLanguage(rawValue: value) ?? .english
    }

    func text(_ english: String, _ russian: String) -> String {
        switch self {
        case .english: english
        case .russian: russian
        }
    }
}
