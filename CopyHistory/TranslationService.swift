import Foundation
import NaturalLanguage
import Translation

enum TranslationError: LocalizedError {
    case unavailable
    case languageNotDetected
    case alreadyInYourLanguage
    case unsupportedPair(source: String, target: String)
    case languageNotInstalled(source: String, target: String)

    /// Errors a web translator cannot help with: the text itself is the problem.
    var isAboutTheText: Bool {
        switch self {
        case .languageNotDetected, .alreadyInYourLanguage: return true
        default: return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return String(localized: "Translation needs a newer version of macOS.")
        case .languageNotDetected:
            return String(localized: "The language of this text could not be detected.")
        case .alreadyInYourLanguage:
            return String(localized: "This text is already in your language.")
        case .unsupportedPair(let source, let target):
            return String(localized: "Translating from \(source) to \(target) is not supported.")
        case .languageNotInstalled(let source, let target):
            return String(localized: "The language data for \(source) to \(target) is not installed. Download it in System Settings > General > Language & Region > Translation Languages.")
        }
    }
}

/// Translates on the device with Apple's Translation framework.
/// The source language is detected; the target is the user's language (English if the text is already in it).
enum TranslationService {
    static var isAvailable: Bool {
        if #available(macOS 26.0, *) { return true }
        return false
    }

    static func translate(_ text: String) async throws -> String {
        guard #available(macOS 26.0, *) else { throw TranslationError.unavailable }

        guard let detected = NLLanguageRecognizer.dominantLanguage(for: text) else {
            throw TranslationError.languageNotDetected
        }
        let source = Locale.Language(identifier: detected.rawValue)
        let target = try targetLanguage(for: source)
        let names = (source: displayName(source), target: displayName(target))

        switch await LanguageAvailability().status(from: source, to: target) {
        case .installed:
            break
        case .supported:
            throw TranslationError.languageNotInstalled(source: names.source, target: names.target)
        case .unsupported:
            throw TranslationError.unsupportedPair(source: names.source, target: names.target)
        @unknown default:
            throw TranslationError.unsupportedPair(source: names.source, target: names.target)
        }

        let session = TranslationSession(installedSource: source, target: target)
        return try await session.translate(text).targetText
    }

    /// The user's own language, or English when the text is already in it.
    @available(macOS 26.0, *)
    static func targetLanguage(for source: Locale.Language, preferred: [String] = Locale.preferredLanguages) throws -> Locale.Language {
        let mine = Locale.Language(identifier: preferred.first ?? "en")
        guard mine.languageCode == source.languageCode else { return mine }
        let english = Locale.Language(identifier: "en")
        guard source.languageCode != english.languageCode else { throw TranslationError.alreadyInYourLanguage }
        return english
    }

    @available(macOS 26.0, *)
    private static func displayName(_ language: Locale.Language) -> String {
        let code = language.languageCode?.identifier ?? language.minimalIdentifier
        return Locale.current.localizedString(forLanguageCode: code) ?? code
    }
}
