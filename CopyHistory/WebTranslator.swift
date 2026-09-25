import Foundation
import NaturalLanguage

/// Opens a text in a web translator (DeepL or Google Translate) when it cannot be translated on the device.
enum WebTranslator {
    enum Service: String, CaseIterable, Identifiable {
        case deepL
        case google

        var id: String { rawValue }

        var title: String {
            switch self {
            case .deepL: return "DeepL"
            case .google: return "Google Translate"
            }
        }
    }

    static let settingKey = "webTranslatorService"

    /// The translator the user picked in Settings (DeepL by default).
    static var preferred: Service {
        UserDefaults.standard.string(forKey: settingKey).flatMap(Service.init(rawValue:)) ?? .deepL
    }

    /// Longer text is cut for the address; the full text is put on the clipboard as well.
    static let maxCharactersInURL = 1500

    /// Source language (nil when it cannot be detected) and target language, as two-letter codes.
    /// The target is the user's language, or English when the text is already in it.
    static func languages(for text: String, preferred: [String] = Locale.preferredLanguages) -> (source: String?, target: String) {
        let mine = languageCode(fromIdentifier: preferred.first ?? "en")
        let source = NLLanguageRecognizer.dominantLanguage(for: text).map { languageCode(fromIdentifier: $0.rawValue) }
        guard let source else { return (nil, mine) }
        return (source, source == mine ? "en" : mine)
    }

    static func url(for service: Service, text: String, source: String?, target: String) -> URL? {
        let clipped = String(text.prefix(maxCharactersInURL))
        switch service {
        case .google:
            var components = URLComponents(string: "https://translate.google.com/")
            components?.queryItems = [
                URLQueryItem(name: "sl", value: source.map { googleCode($0) } ?? "auto"),
                URLQueryItem(name: "tl", value: googleCode(target)),
                URLQueryItem(name: "text", value: clipped),
                URLQueryItem(name: "op", value: "translate"),
            ]
            return components?.url
        case .deepL:
            // DeepL reads "#source/target/text"; its text must be percent-encoded with "/" written as "\/".
            let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
            let encoded = (clipped.addingPercentEncoding(withAllowedCharacters: unreserved) ?? "")
                .replacingOccurrences(of: "%2F", with: "%5C%2F")
            return URL(string: "https://www.deepl.com/translator#\(source.map { deepLCode($0) } ?? "auto")/\(deepLCode(target))/\(encoded)")
        }
    }

    private static func languageCode(fromIdentifier identifier: String) -> String {
        let lowered = identifier.lowercased()
        if lowered.hasPrefix("zh") {
            return lowered.contains("hant") || lowered.contains("tw") || lowered.contains("hk") ? "zh-Hant" : "zh-Hans"
        }
        return Locale(identifier: identifier).languageCode ?? String(identifier.prefix(2))
    }

    private static func googleCode(_ code: String) -> String {
        switch code {
        case "zh-Hans": return "zh-CN"
        case "zh-Hant": return "zh-TW"
        default: return code
        }
    }

    private static func deepLCode(_ code: String) -> String {
        code.hasPrefix("zh") ? "zh" : code
    }
}
