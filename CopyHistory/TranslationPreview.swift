import Foundation

/// The tooltip of the Translate button: translates the text when the pointer arrives and shows the result,
/// or says that the web translator will be opened when this Mac cannot translate it.
@MainActor
final class TranslationPreview: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case translated(String)
        /// The text itself cannot be translated (already in your language, language not detected).
        case notNeeded(String)
        /// This Mac cannot translate it; the web translator opens instead.
        case webFallback
    }

    static let maxCharacters = 500
    static let maxTooltipCharacters = 600

    private static var cache: [String: State] = [:]

    @Published private(set) var state: State = .idle

    private let isAvailable: () -> Bool
    private let translate: (String) async throws -> String
    private let webTranslatorName: () -> String
    private var task: Task<Void, Never>?

    init(isAvailable: @escaping () -> Bool = { TranslationService.isAvailable },
         translate: @escaping (String) async throws -> String = { try await TranslationService.translate($0) },
         webTranslatorName: @escaping () -> String = { WebTranslator.preferred.title }) {
        self.isAvailable = isAvailable
        self.translate = translate
        self.webTranslatorName = webTranslatorName
    }

    /// Call when the pointer arrives on the button.
    func load(_ text: String) {
        let source = String(text.prefix(Self.maxCharacters))
        let isCut = text.count > Self.maxCharacters
        if let cached = Self.cache[source] {
            state = cached
            return
        }
        guard isAvailable() else {
            state = .webFallback
            return
        }
        if case .loading = state { return }
        state = .loading
        task = Task { [weak self] in
            guard let self else { return }
            let result: State
            do {
                let translated = try await translate(source)
                result = .translated(isCut ? translated + "…" : translated)
            } catch is CancellationError {
                return
            } catch let error as TranslationError where error.isAboutTheText {
                result = .notNeeded(error.localizedDescription)
            } catch {
                result = .webFallback
            }
            Self.cache[source] = result
            state = result
        }
    }

    var tooltip: String {
        switch state {
        case .idle:
            return String(localized: "Translate the text into your language (or English if it is already in your language)")
        case .loading:
            return String(localized: "Translating…")
        case .translated(let text):
            return String(text.prefix(Self.maxTooltipCharacters))
        case .notNeeded(let message):
            return message
        case .webFallback:
            return String(localized: "Can't translate on this Mac. Clicking opens \(webTranslatorName()) in your browser.")
        }
    }
}
