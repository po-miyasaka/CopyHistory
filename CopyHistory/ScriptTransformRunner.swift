import Foundation
import JavaScriptCore

enum ScriptTransformError: LocalizedError, Equatable {
    case missingTransformFunction
    case scriptError(String)
    case invalidReturnValue
    case timeout

    var errorDescription: String? {
        switch self {
        case .missingTransformFunction:
            return String(localized: "The script must define function transform(text).")
        case .scriptError(let message):
            return message
        case .invalidReturnValue:
            return String(localized: "transform(text) must return a string.")
        case .timeout:
            return String(localized: "The script took too long and was stopped.")
        }
    }
}

/// Runs user-provided JavaScript of the form `function transform(text) { return "..." }`
/// inside JavaScriptCore (no file/network access, no Node/DOM APIs).
enum ScriptTransformRunner {
    static let timeout: TimeInterval = 2

    static let templateScript = """
    function transform(text) {
      return text.trim();
    }
    """

    static func run(script: String, input: String) -> Result<String, ScriptTransformError> {
        let outcome = ResultBox()
        let finished = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .userInitiated).async {
            outcome.set(evaluate(script: script, input: input))
            finished.signal()
        }

        guard finished.wait(timeout: .now() + timeout) == .success,
              let result = outcome.get()
        else { return .failure(.timeout) }
        return result
    }

    private static func evaluate(script: String, input: String) -> Result<String, ScriptTransformError> {
        guard let context = JSContext() else {
            return .failure(.scriptError("JavaScript engine unavailable"))
        }

        context.evaluateScript(script)
        if let exception = context.exception {
            return .failure(.scriptError(exception.toString() ?? "Unknown error"))
        }

        guard let function = context.objectForKeyedSubscript("transform"),
              function.isObject,
              function.objectForKeyedSubscript("call")?.isObject == true
        else { return .failure(.missingTransformFunction) }

        let returned = function.call(withArguments: [input])
        if let exception = context.exception {
            return .failure(.scriptError(exception.toString() ?? "Unknown error"))
        }

        guard let returned, returned.isString, let output = returned.toString() else {
            return .failure(.invalidReturnValue)
        }
        return .success(output)
    }
}

private final class ResultBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Result<String, ScriptTransformError>?

    func set(_ newValue: Result<String, ScriptTransformError>) {
        lock.lock(); defer { lock.unlock() }
        value = newValue
    }

    func get() -> Result<String, ScriptTransformError>? {
        lock.lock(); defer { lock.unlock() }
        return value
    }
}
