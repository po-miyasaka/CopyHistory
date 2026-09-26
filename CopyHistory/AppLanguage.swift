import AppKit

/// The language the app's own text is shown in. "System" follows the Mac's language settings.
/// A macOS app reads its language when it launches, so a change needs a restart to show.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case japanese = "ja"
    case german = "de"
    case spanish = "es"
    case french = "fr"
    case korean = "ko"
    case simplifiedChinese = "zh-Hans"

    static let storageKey = "appLanguage"
    private static let appleLanguagesKey = "AppleLanguages"

    var id: String { rawValue }

    /// Each language is named in itself, so it can be found even when the current language is not understood.
    var title: String {
        switch self {
        case .system: return String(localized: "System default")
        case .english: return "English"
        case .japanese: return "日本語"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .french: return "Français"
        case .korean: return "한국어"
        case .simplifiedChinese: return "简体中文"
        }
    }

    /// What is saved as the choice (the language in use after the next launch).
    static func stored(in defaults: UserDefaults = .standard) -> AppLanguage {
        defaults.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    /// Saves the choice and makes the next launch use it.
    func save(in defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.storageKey)
        if self == .system {
            defaults.removeObject(forKey: Self.appleLanguagesKey)
        } else {
            defaults.set([rawValue], forKey: Self.appleLanguagesKey)
        }
    }

    /// Starts a new copy of the app and quits this one, so the saved language is used.
    static func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            if let error { NSLog("Could not relaunch the app: \(error)") }
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}
