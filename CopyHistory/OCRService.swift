import Foundation
import ImageIO
import Vision

/// Reads text out of images on the device with Vision.
///
/// Tuned to be cheap: one pass per image (the caller stores the result), large images are shrunk first,
/// and language correction is off. The `.fast` level cannot read Japanese, so `.accurate` is required.
enum OCRService {
    static let maxLongEdge = 2000
    static let minEdge = 32
    static let languages = ["ja-JP", "en-US"]

    /// The recognized text (empty when the image has none), or nil when the data is not a readable image.
    static func recognizeText(in data: Data) async -> String? {
        await Task.detached(priority: .utility) { recognizeSynchronously(data) }.value
    }

    private static func recognizeSynchronously(_ data: Data) -> String? {
        guard let image = decodedImage(from: data) else { return nil }
        guard min(image.width, image.height) >= minEdge else { return "" }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages
        request.usesLanguageCorrection = false
        do {
            try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        } catch {
            NSLog("OCR failed: \(error)")
            return nil
        }
        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }

    private static func decodedImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0

        if max(width, height) <= maxLongEdge {
            return CGImageSourceCreateImageAtIndex(source, 0, nil)
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxLongEdge,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
