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
