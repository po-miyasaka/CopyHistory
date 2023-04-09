//
//  Persistence.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import Cocoa
import CoreData
import CryptoKit
import SwiftUI

@MainActor
final class PasteboardService: ObservableObject {
    @Published var searchText: String = ""
    @Published var copiedItems: [CopiedItem] = []
    @Published var isShowingOnlyFavorite: Bool = false
    @Published var isShowingOnlyMemoed: Bool = false
    static let displayedItemCountDefaultValue = 100
    @AppStorage("displayedItemCount") var displayedItemCount: Int = displayedItemCountDefaultValue {
        didSet {
            updateCopiedItems()
        }
    }

    lazy var displayedItemCountBinding: Binding<String> = .init(
        get: { [weak self] in
            String(self?.displayedItemCount ?? Self.displayedItemCountDefaultValue)
        },
        set: { [weak self] in
            self?.displayedItemCount = Int($0) ?? 0
        }
    )
    private let persistenceController = PersistenceController()
    private var pasteBoard: NSPasteboard { NSPasteboard.general }
    private var latestChangeCount = 0
    private lazy var timer: Timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)

    static func build() -> PasteboardService {
        let p = PasteboardService()
        p.setup()
        return p
    }

    private init() {}

    func updateCopiedItems() {
        // If Task is used, SwiftUI Animation won't work...
        // Even if the method is nonisolated and synchronous, as long as it's in Task, the animation doesn't work
        Task {
            copiedItems = await persistenceController.getSavedCopiedItems(with: searchText, isShowingOnlyFavorite: isShowingOnlyFavorite, isShowingOnlyMemoed: isShowingOnlyMemoed, limit: displayedItemCount)
        }
    }

    @objc func timerLoop() {
        Task {
            if pasteBoard.changeCount == latestChangeCount { return } // If there is no change, do nothing.
            latestChangeCount = pasteBoard.changeCount

            guard let newItem = pasteBoard.pasteboardItems?.first,
                let type = newItem.availableType(from: newItem.types),
                let data = newItem.data(forType: type),
                pasteBoard.types?.contains(where: { $0.rawValue.contains("com.agilebits.onepassword") }) == false else { return }

            let dataHash = CryptoKit.SHA256.hash(data: data).description
            if let alreadySavedItem = await persistenceController.getCopiedItem(from: dataHash) {
                // Existing
                alreadySavedItem.updateDate = Date()
            } else {
                // New
                let copiedItem = await persistenceController.create(type: CopiedItem.self)
                let str = newItem.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
                copiedItem.rawString = str
                copiedItem.content = data

                copiedItem.name = String((str ?? "No Name").prefix(100))
                copiedItem.binarySize = Int64(data.count)
                copiedItem.contentTypeString = type.rawValue
                copiedItem.updateDate = Date()
                copiedItem.dataHash = dataHash
            }

            await persistenceController.persists()
            updateCopiedItems()
        }
    }

    private func setup() {
        timer.fire()
        updateCopiedItems()
    }

    func search() {
        updateCopiedItems()
    }

    func filterFavorited() {
        isShowingOnlyFavorite.toggle()
        updateCopiedItems()
    }

    func filterMemoed() {
        isShowingOnlyMemoed.toggle()
        updateCopiedItems()
    }

    func didSelected(_ copiedItem: CopiedItem) {
        guard let contentTypeString = copiedItem.contentTypeString,
            let data = copiedItem.content
        else { return }
        let type = NSPasteboard.PasteboardType(contentTypeString)
        let item = NSPasteboardItem()
        item.setData(data, forType: type)
        if let rawString = copiedItem.rawString {
            item.setString(rawString, forType: .string)
        }
        pasteBoard.declareTypes([type, .string], owner: nil)
        pasteBoard.writeObjects([item])

        copiedItem.updateDate = Date()
        Task {
            await persistenceController.persists()
            updateCopiedItems()
        }
    }

    func toggleFavorite(_ copiedItem: CopiedItem) {
        copiedItem.favorite.toggle()
        Task {
            await persistenceController.persists()
            updateCopiedItems()
        }
    }

    func delete(_ copiedItem: CopiedItem) {
        Task {
            await persistenceController.delete(copiedItem)
            updateCopiedItems()
        }
    }

    func saveMemo(_ copiedItem: CopiedItem, memo: String) {
        copiedItem.memo = memo
        Task {
            await persistenceController.persists()
            updateCopiedItems()
        }
    }

    func clearAll() {
        Task {
            await persistenceController.clearAllItems()
            updateCopiedItems()
        }
    }
}

private actor PersistenceController: ObservableObject {
    let container: NSPersistentContainer
    init() {
        container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - CRUD

    func create<T: NSManagedObject>(type: T.Type) -> T {
        type.init(context: container.viewContext)
    }

    func getSavedCopiedItems(with text: String? = nil, isShowingOnlyFavorite: Bool = false, isShowingOnlyMemoed: Bool = false, limit: Int? = nil) -> [CopiedItem] {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        fetchRequest.returnsObjectsAsFaults = true
        var updateDateSort = SortDescriptor<CopiedItem>(\.updateDate)
        var favoritePredicate: NSPredicate?
        if isShowingOnlyFavorite {
            favoritePredicate = NSPredicate(format: "favorite == YES")
        }
        var memoedPredicate: NSPredicate?
        if isShowingOnlyMemoed {
            memoedPredicate = NSPredicate(format: "NOT (memo == %@ OR memo == nil OR memo == '')")
        }
        var textPredicate: NSPredicate?
        if let text = text, !text.isEmpty {
            textPredicate = NSPredicate(format: "contentTypeString Contains[c] %@ OR rawString Contains[c] %@ OR name Contains[c] %@ OR memo Contains[c] %@", arguments: getVaList([text, text, text, text]))
        }

        let predicate: NSPredicate? = NSCompoundPredicate(andPredicateWithSubpredicates: [textPredicate, favoritePredicate, memoedPredicate].compactMap { $0 })
        fetchRequest.predicate = predicate
        if let limit {
            fetchRequest.fetchLimit = limit
        }
        updateDateSort.order = .reverse
        fetchRequest.sortDescriptors = [NSSortDescriptor(updateDateSort)]
        return (try? container.viewContext.fetch(fetchRequest)) ?? []
    }

    func getCopiedItem(from hash: String?) -> CopiedItem? {
        guard let hash = hash else { return nil }
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        let predicate = NSPredicate(format: "dataHash == %@", arguments: getVaList([hash]))
        fetchRequest.predicate = predicate
        return (try? container.viewContext.fetch(fetchRequest))?.first
    }

    func clearAllItems() {
        let items = getSavedCopiedItems()
        items.filter { !$0.favorite }.forEach {
            container.viewContext.delete($0)
        }
        persists()
    }

    func delete(_ copiedItem: CopiedItem) {
        container.viewContext.delete(copiedItem)
        persists()
    }

    func persists() {
        try? container.viewContext.save()
    }
}

extension CopiedItem {
    static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()

    var binarySizeString: String {
        if binarySize == 0 { return "-" }
        return Self.formatter.string(fromByteCount: binarySize)
    }

    var attributeString: NSAttributedString? {
        if let att = rtfStringCached {
            return att
        }
        guard contentTypeString?.contains("rtf") == true, let content = content else { return nil }

        let attributeString = (try? NSAttributedString(data: content, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil))
        rtfStringCached = attributeString
        return attributeString
    }

    var htmlString: NSAttributedString? {
        if let att = htmlStringCached {
            return att
        }
        guard contentTypeString?.contains("html") == true, let content = content else { return nil }

        let attributeString = (try? NSAttributedString(data: content, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil))
        htmlStringCached = attributeString
        return attributeString
    }

    var fileURL: URL? {
        guard contentTypeString?.contains("file-url") == true,
            let content = content,
            let path = String(data: content, encoding: .utf8),
            let url = URL(string: path) else { return nil }
        //            url.startAccessingSecurityScopedResource()
        return url
    }
}
