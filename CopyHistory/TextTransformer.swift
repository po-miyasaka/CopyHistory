import Foundation
import AppKit
import CoreImage

enum TextTransformer {
    static func apply(_ action: TransformAction, to input: String) -> String? {
        switch action {
        case .jsonPretty:
            return prettyPrintJSON(input)
        case .wrapJapaneseBrackets:
            return "「\(input)」"
        case .wrapDoubleQuotes:
            return "\"\(input)\""
        case .numberCommaFormat:
            return formatNumberWithCommas(input)
        case .escapeNewlines:
            return input
                .replacingOccurrences(of: "\r\n", with: "\\r\\n")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
        case .urlEncode:
            return input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        case .urlDecode:
            return input.removingPercentEncoding
        case .base64Encode:
            return Data(input.utf8).base64EncodedString()
        case .base64Decode:
            guard let data = Data(base64Encoded: input),
                  let decoded = String(data: data, encoding: .utf8)
            else { return nil }
            return decoded
        case .uppercase:
            return input.uppercased()
        case .lowercase:
            return input.lowercased()
        case .trimWhitespace:
            return input.trimmingCharacters(in: .whitespacesAndNewlines)
        case .showQRCode:
            return nil
        case .custom(let transform):
            return applyCustom(transform, to: input)
        }
    }

    static func generateQRCode(from string: String) -> NSImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator")
        else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let rep = NSCIImageRep(ciImage: scaled)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }

    private static func prettyPrintJSON(_ input: String) -> String? {
        guard let data = input.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: pretty, encoding: .utf8)
        else { return nil }
        return result
    }

    private static func formatNumberWithCommas(_ input: String) -> String {
        let stripped = input.replacingOccurrences(of: ",", with: "")
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        if let number = Double(stripped) {
            return formatter.string(from: NSNumber(value: number)) ?? input
        }
        return input
    }

    private static func applyCustom(_ transform: CustomTransform, to input: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: transform.pattern)
        else { return nil }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: transform.replacement)
    }
}
