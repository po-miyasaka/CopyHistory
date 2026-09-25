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
    case translate
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
        case .translate: return "translate"
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
        case .translate: return String(localized: "Translate")
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
        case .translate: return "globe"
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
        case .translate: return "Translate the text into your language (or English if it is already in your language)"
        case .custom: return "Run a custom JavaScript transform"
        }
    }

    static var allBuiltIn: [TransformAction] {
        let actions: [TransformAction] = [
            .jsonPretty, .wrapJapaneseBrackets, .wrapDoubleQuotes,
            .numberCommaFormat, .escapeNewlines, .urlEncode, .urlDecode,
            .base64Encode, .base64Decode, .uppercase, .lowercase,
            .trimWhitespace, .showQRCode
        ]
        return TranslationService.isAvailable ? actions + [.translate] : actions
    }
}

struct CustomTransform: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var script: String
}

final class TransformUsageTracker: ObservableObject {
    static let shared = TransformUsageTracker()

    private static let userDefaultsKey = "recentTransformActionIDs"
    private static let maxStoredCount = 50

    @Published private(set) var recentActionIDs: [String]

    private init() {
        recentActionIDs = UserDefaults.standard.stringArray(forKey: Self.userDefaultsKey) ?? []
    }

    func recordUsage(_ action: TransformAction) {
        var updated = recentActionIDs.filter { $0 != action.id }
        updated.insert(action.id, at: 0)
        recentActionIDs = Array(updated.prefix(Self.maxStoredCount))
        UserDefaults.standard.set(recentActionIDs, forKey: Self.userDefaultsKey)
    }

    /// Most recently used first; actions never used keep their original order after them.
    func sorted(_ actions: [TransformAction]) -> [TransformAction] {
        let rank = Dictionary(recentActionIDs.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return actions.enumerated()
            .sorted { lhs, rhs in
                let lhsRank = rank[lhs.element.id] ?? Int.max
                let rhsRank = rank[rhs.element.id] ?? Int.max
                return lhsRank == rhsRank ? lhs.offset < rhs.offset : lhsRank < rhsRank
            }
            .map(\.element)
    }
}
