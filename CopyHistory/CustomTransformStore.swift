import Foundation
import Combine

final class CustomTransformStore: ObservableObject {
    static let shared = CustomTransformStore()

    private static let userDefaultsKey = "customTransformScript"
    private static let actionID = "custom"

    @Published var script: String {
        didSet { UserDefaults.standard.set(script, forKey: Self.userDefaultsKey) }
    }

    var transforms: [CustomTransform] {
        guard !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return [CustomTransform(id: Self.actionID, name: "Custom", script: script)]
    }

    private init() {
        script = UserDefaults.standard.string(forKey: Self.userDefaultsKey) ?? ScriptTransformRunner.templateScript
    }

    func resetToDefault() {
        script = ScriptTransformRunner.templateScript
    }
}
