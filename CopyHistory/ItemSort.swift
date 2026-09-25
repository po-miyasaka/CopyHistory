import Foundation
import SwiftUI

struct ItemSort: Equatable, Codable {
    enum Field: String, CaseIterable, Identifiable, Codable {
        case updated
        case saved
        case length
        case size

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .updated: return "Updated date"
            case .saved: return "Saved date"
            case .length: return "Character count"
            case .size: return "Size"
            }
        }

        fileprivate var key: String {
            switch self {
            case .updated: return "updateDate"
            case .saved: return "createdDate"
            case .length: return "textLength"
            case .size: return "binarySize"
            }
        }
    }

    var field: Field = .updated
    var ascending = false

    var sortDescriptors: [NSSortDescriptor] {
        var descriptors = [NSSortDescriptor(key: field.key, ascending: ascending)]
        if field != .updated {
            descriptors.append(NSSortDescriptor(key: Field.updated.key, ascending: false))
        }
        return descriptors
    }
}
