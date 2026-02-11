import Foundation

enum TransformAction: Identifiable, Hashable {
    case jsonPretty
    case wrapJapaneseBrackets
    case wrapDoubleQuotes
    case numberCommaFormat
    case escapeNewlines
    case urlEncode
    case urlDecode
    case base64Encode
    case base64Decode
    case uppercase
    case lowercase
    case trimWhitespace
    case showQRCode
    case custom(CustomTransform)

    var id: String {
        switch self {
        case .jsonPretty: return "jsonPretty"
        case .wrapJapaneseBrackets: return "wrapJapaneseBrackets"
        case .wrapDoubleQuotes: return "wrapDoubleQuotes"
        case .numberCommaFormat: return "numberCommaFormat"
        case .escapeNewlines: return "escapeNewlines"
        case .urlEncode: return "urlEncode"
        case .urlDecode: return "urlDecode"
        case .base64Encode: return "base64Encode"
        case .base64Decode: return "base64Decode"
        case .uppercase: return "uppercase"
        case .lowercase: return "lowercase"
        case .trimWhitespace: return "trimWhitespace"
        case .showQRCode: return "showQRCode"
        case .custom(let t): return "custom_\(t.id)"
        }
    }

    var displayName: String {
        switch self {
        case .jsonPretty: return "JSON"
        case .wrapJapaneseBrackets: return "「」"
        case .wrapDoubleQuotes: return "\"\""
        case .numberCommaFormat: return "1,234"
        case .escapeNewlines: return "\\n"
        case .urlEncode: return "URL Enc"
        case .urlDecode: return "URL Dec"
        case .base64Encode: return "B64 Enc"
        case .base64Decode: return "B64 Dec"
        case .uppercase: return "ABC"
        case .lowercase: return "abc"
        case .trimWhitespace: return "Trim"
        case .showQRCode: return "QR"
        case .custom(let t): return t.name
        }
    }

    var iconName: String {
        switch self {
        case .jsonPretty: return "curlybraces"
        case .wrapJapaneseBrackets: return "textformat.abc"
        case .wrapDoubleQuotes: return "text.quote"
        case .numberCommaFormat: return "number"
        case .escapeNewlines: return "return"
        case .urlEncode: return "link"
        case .urlDecode: return "link.badge.plus"
        case .base64Encode: return "lock"
        case .base64Decode: return "lock.open"
        case .uppercase: return "textformat.size.larger"
        case .lowercase: return "textformat.size.smaller"
        case .trimWhitespace: return "scissors"
        case .showQRCode: return "qrcode"
        case .custom: return "gearshape"
        }
    }

    var helpText: String {
        switch self {
        case .jsonPretty: return "Format JSON with indentation for readability"
        case .wrapJapaneseBrackets: return "Wrap text with Japanese brackets「」"
        case .wrapDoubleQuotes: return "Wrap text with double quotes \"\""
        case .numberCommaFormat: return "Format numbers with comma separators (e.g. 1,234,567)"
        case .escapeNewlines: return "Replace line breaks with \\n"
        case .urlEncode: return "Encode text for use in URLs (percent-encoding)"
        case .urlDecode: return "Decode percent-encoded URL text back to readable text"
        case .base64Encode: return "Encode text to Base64 format"
        case .base64Decode: return "Decode Base64 text back to original text"
        case .uppercase: return "Convert all characters to uppercase"
        case .lowercase: return "Convert all characters to lowercase"
        case .trimWhitespace: return "Remove leading and trailing whitespace and newlines"
        case .showQRCode: return "Generate a QR code from the text"
        case .custom(let t): return "Custom transform: \(t.pattern) → \(t.replacement)"
        }
    }

    static var allBuiltIn: [TransformAction] {
        [.jsonPretty, .wrapJapaneseBrackets, .wrapDoubleQuotes,
         .numberCommaFormat, .escapeNewlines, .urlEncode, .urlDecode,
         .base64Encode, .base64Decode, .uppercase, .lowercase,
         .trimWhitespace, .showQRCode]
    }
}

struct CustomTransform: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var pattern: String
    var replacement: String
}

final class TransformUsageTracker: ObservableObject {
    static let shared = TransformUsageTracker()
    @Published private(set) var recentActionIDs: [String] = []

    private init() {}

    func recordUsage(_ action: TransformAction) {
        recentActionIDs.removeAll { $0 == action.id }
        recentActionIDs.insert(action.id, at: 0)
    }

    func sorted(_ actions: [TransformAction]) -> [TransformAction] {
        guard !recentActionIDs.isEmpty else { return actions }
        return actions.sorted { a, b in
            let indexA = recentActionIDs.firstIndex(of: a.id) ?? Int.max
            let indexB = recentActionIDs.firstIndex(of: b.id) ?? Int.max
            if indexA == indexB {
                return false
            }
            return indexA < indexB
        }
    }
}
