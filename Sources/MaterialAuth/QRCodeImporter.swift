import AppKit
import CoreImage
import Foundation
import UniformTypeIdentifiers

enum QRCodeImporter {
    @MainActor
    static func chooseAndRead() throws -> String? {
        let panel = NSOpenPanel()
        panel.title = AppLanguage.current.text("Choose an Image with a QR Code", "Выберите изображение с QR-кодом")
        panel.prompt = AppLanguage.current.text("Read QR Code", "Считать QR-код")
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff, .image]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard let image = NSImage(contentsOf: url) else {
            throw QRImportError.invalidImage
        }
        return try read(from: image)
    }

    static func read(from image: NSImage) throws -> String {
        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let ciImage = CIImage(bitmapImageRep: bitmap)
        else {
            throw QRImportError.invalidImage
        }

        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: context,
            options: options
        ) else {
            throw QRImportError.notFound
        }

        let message = detector.features(in: ciImage)
            .compactMap { ($0 as? CIQRCodeFeature)?.messageString }
            .first

        guard let message else { throw QRImportError.notFound }
        guard message.lowercased().hasPrefix("otpauth://") else {
            throw QRImportError.unsupportedContent
        }
        return message
    }
}

enum QRImportError: LocalizedError {
    case invalidImage
    case notFound
    case unsupportedContent

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            AppLanguage.current.text("Could not open the image.", "Не удалось открыть изображение.")
        case .notFound:
            AppLanguage.current.text("No QR code was found in the image.", "На изображении не найден QR-код.")
        case .unsupportedContent:
            AppLanguage.current.text(
                "The QR code does not contain an otpauth link.",
                "QR-код не содержит ссылку otpauth."
            )
        }
    }
}
