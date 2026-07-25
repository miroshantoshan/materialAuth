import AppKit
import CoreImage
import Foundation
import UniformTypeIdentifiers

enum QRCodeImporter {
    @MainActor
    static func chooseAndRead() throws -> String? {
        let panel = NSOpenPanel()
        panel.title = "Choose an Image with a QR Code"
        panel.prompt = "Read QR Code"
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
        case .invalidImage: "Could not open the image."
        case .notFound: "No QR code was found in the image."
        case .unsupportedContent: "The QR code does not contain an otpauth link."
        }
    }
}
