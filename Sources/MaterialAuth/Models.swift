import Foundation
import SwiftUI

struct OTPAccount: Identifiable, Codable, Equatable {
    let id: UUID
    var issuer: String
    var name: String
    var digits: Int
    var period: Int
    var algorithm: OTPAlgorithm
    var tint: String

    init(
        id: UUID = UUID(),
        issuer: String,
        name: String,
        digits: Int = 6,
        period: Int = 30,
        algorithm: OTPAlgorithm = .sha1,
        tint: String = "primary"
    ) {
        self.id = id
        self.issuer = issuer
        self.name = name
        self.digits = digits
        self.period = period
        self.algorithm = algorithm
        self.tint = tint
    }
}

enum OTPAlgorithm: String, Codable, CaseIterable, Identifiable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"

    var id: String { rawValue }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Как в системе"
        case .light: "Светлая"
        case .dark: "Тёмная"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum M3Palette: String, CaseIterable, Identifiable {
    case violet
    case blue
    case green
    case coral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .violet: "Фиолетовая"
        case .blue: "Синяя"
        case .green: "Зелёная"
        case .coral: "Коралловая"
        }
    }

    var seed: Color {
        switch self {
        case .violet: Color(red: 0.40, green: 0.31, blue: 0.64)
        case .blue: Color(red: 0.13, green: 0.40, blue: 0.68)
        case .green: Color(red: 0.20, green: 0.47, blue: 0.34)
        case .coral: Color(red: 0.68, green: 0.27, blue: 0.28)
        }
    }

    var container: Color {
        switch self {
        case .violet: Color(red: 0.91, green: 0.87, blue: 1.00)
        case .blue: Color(red: 0.84, green: 0.91, blue: 1.00)
        case .green: Color(red: 0.82, green: 0.94, blue: 0.86)
        case .coral: Color(red: 1.00, green: 0.86, blue: 0.85)
        }
    }
}
