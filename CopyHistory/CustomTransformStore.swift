import Foundation
import Combine

final class CustomTransformStore: ObservableObject {
    static let shared = CustomTransformStore()

    private static let listKey = "customTransformActions"
    private static let legacyScriptKey = "customTransformScript"
    private static let defaultName = "Custom"
    private static let defaultID = "custom"

    @Published var transforms: [CustomTransform] {
        didSet { save() }
    }

    /// Transforms that can run: scripts must not be empty, and blank names fall back to the default label.
    var activeTransforms: [CustomTransform] {
        transforms
            .filter { !$0.script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { transform in
                let hasName = !transform.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                return CustomTransform(id: transform.id, name: hasName ? transform.name : Self.defaultName, script: transform.script)
            }
    }

    private init() {
        transforms = Self.load()
    }

    func add() {
        transforms = transforms + [CustomTransform(name: Self.defaultName, script: ScriptTransformRunner.templateScript)]
    }

    func remove(id: String) {
        transforms = transforms.filter { $0.id != id }
    }

    func resetScript(id: String) {
        transforms = transforms.map { transform in
            transform.id == id
                ? CustomTransform(id: transform.id, name: transform.name, script: ScriptTransformRunner.templateScript)
                : transform
        }
    }

    private static func load() -> [CustomTransform] {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: listKey),
           let decoded = try? JSONDecoder().decode([CustomTransform].self, from: data) {
            return decoded
        }
        // Earlier builds kept a single script; carry it over as the first action.
        let script = defaults.string(forKey: legacyScriptKey) ?? ScriptTransformRunner.templateScript
        return [CustomTransform(id: defaultID, name: defaultName, script: script)]
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(transforms) else { return }
        UserDefaults.standard.set(data, forKey: Self.listKey)
    }
}
