import CryptoKit
import Foundation

enum TOTPError: LocalizedError {
    case invalidSecret
    case invalidURL
    case unsupportedType

    var errorDescription: String? {
        switch self {
        case .invalidSecret: "Секретный ключ имеет неверный формат."
        case .invalidURL: "Не удалось прочитать ссылку otpauth."
        case .unsupportedType: "Поддерживаются только TOTP-ссылки."
        }
    }
}

enum TOTP {
    static func code(
        secret: String,
        date: Date = Date(),
        digits: Int = 6,
        period: Int = 30,
        algorithm: OTPAlgorithm = .sha1
    ) throws -> String {
        guard let keyData = Base32.decode(secret), !keyData.isEmpty else {
            throw TOTPError.invalidSecret
        }

        var counter = UInt64(floor(date.timeIntervalSince1970 / Double(period))).bigEndian
        let counterData = Data(bytes: &counter, count: MemoryLayout<UInt64>.size)
        let key = SymmetricKey(data: keyData)
        let digest: Data

        switch algorithm {
        case .sha1:
            digest = Data(HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key))
        case .sha256:
            digest = Data(HMAC<SHA256>.authenticationCode(for: counterData, using: key))
        case .sha512:
            digest = Data(HMAC<SHA512>.authenticationCode(for: counterData, using: key))
        }

        let offset = Int(digest.last! & 0x0f)
        let value = digest[offset ..< offset + 4].reduce(UInt32(0)) {
            ($0 << 8) | UInt32($1)
        } & 0x7fff_ffff
        let modulus = UInt32(pow(10.0, Double(digits)))
        return String(format: "%0*u", digits, value % modulus)
    }

    static func remaining(period: Int, date: Date = Date()) -> Int {
        period - Int(date.timeIntervalSince1970) % period
    }
}

enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    static func decode(_ input: String) -> Data? {
        let cleaned = input
            .uppercased()
            .filter { !$0.isWhitespace && $0 != "-" && $0 != "=" }

        guard !cleaned.isEmpty else { return nil }

        var buffer = 0
        var bitsLeft = 0
        var result = Data()

        for character in cleaned {
            guard let index = alphabet.firstIndex(of: character) else { return nil }
            buffer = (buffer << 5) | index
            bitsLeft += 5

            if bitsLeft >= 8 {
                bitsLeft -= 8
                result.append(UInt8((buffer >> bitsLeft) & 0xff))
            }
        }
        return result
    }
}

struct OTPAuthPayload {
    let account: OTPAccount
    let secret: String

    static func parse(_ value: String) throws -> OTPAuthPayload {
        guard let components = URLComponents(string: value),
              components.scheme?.lowercased() == "otpauth",
              components.host?.lowercased() == "totp"
        else {
            if value.lowercased().hasPrefix("otpauth://") {
                throw TOTPError.unsupportedType
            }
            throw TOTPError.invalidURL
        }

        let label = components.path
            .drop(while: { $0 == "/" })
            .removingPercentEncoding ?? ""
        let parts = label.split(separator: ":", maxSplits: 1).map(String.init)
        let query = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map {
                ($0.name.lowercased(), $0.value ?? "")
            }
        )

        guard let secret = query["secret"], Base32.decode(secret) != nil else {
            throw TOTPError.invalidSecret
        }

        let issuer = query["issuer"] ?? (parts.count > 1 ? parts[0] : "Аккаунт")
        let name = parts.count > 1 ? parts[1] : (parts.first ?? "Без названия")
        let digits = Int(query["digits"] ?? "") ?? 6
        let period = Int(query["period"] ?? "") ?? 30
        let algorithm = OTPAlgorithm(rawValue: (query["algorithm"] ?? "SHA1").uppercased()) ?? .sha1

        return OTPAuthPayload(
            account: OTPAccount(
                issuer: issuer,
                name: name,
                digits: digits,
                period: period,
                algorithm: algorithm
            ),
            secret: secret
        )
    }
}
