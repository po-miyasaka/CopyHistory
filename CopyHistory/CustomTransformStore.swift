import Foundation
import Combine

final class CustomTransformStore: ObservableObject {
    static let shared = CustomTransformStore()

    private static let userDefaultsKey = "customTransforms"

    @Published var transforms: [CustomTransform] = [] {
        didSet { save() }
    }

    private init() {
        load()
    }

    func add(_ transform: CustomTransform) {
        transforms.append(transform)
    }

    func remove(at offsets: IndexSet) {
        transforms.remove(atOffsets: offsets)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
              let decoded = try? JSONDecoder().decode([CustomTransform].self, from: data)
        else { return }
        transforms = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(transforms)
        else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
}
