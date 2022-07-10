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

final class PasteboardService: ObservableObject {
    @Published var searchText: String = ""
    @Published var copiedItems: [CopiedItem] = []
    @Published var isShowingOnlyFavorite: Bool = false

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
        copiedItems = persistenceController.getSavedCopiedItems(with: searchText, isShowingOnlyFavorite: isShowingOnlyFavorite)
    }

    @objc func timerLoop() {
        if pasteBoard.changeCount == latestChangeCount { return } // 変更がなければなにもしない
        latestChangeCount = pasteBoard.changeCount

        guard let newItem = pasteBoard.pasteboardItems?.first,
            let type = newItem.availableType(from: newItem.types),
            let data = newItem.data(forType: type) else { return }
        let dataHash = CryptoKit.SHA256.hash(data: data).description

        if let alreadySavedItem = persistenceController.getCopiedItem(from: dataHash) {
            // すでに存在している
            alreadySavedItem.updateDate = Date()
        } else {
            // 新しい
            let copiedItem = persistenceController.createCopiedItem()
            copiedItem.name = newItem.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
            copiedItem.content = data
            copiedItem.contentTypeString = type.rawValue
            copiedItem.updateDate = Date()
            copiedItem.dataHash = dataHash
        }

        persistenceController.persists()
        updateCopiedItems()
    }

    private func setup() {
        timer.fire()
        updateCopiedItems()
    }

    func search() {
        updateCopiedItems()
    }
    
    func favoriteFilterButtonDidTap() {
        isShowingOnlyFavorite.toggle()
        updateCopiedItems()
    }

    func didSelected(_ copiedItem: CopiedItem) {
        guard let contentTypeString = copiedItem.contentTypeString,
            let contentData = copiedItem.content
        else { return }
        let type = NSPasteboard.PasteboardType(contentTypeString)
        let item = NSPasteboardItem()
        item.setData(contentData, forType: type)
        if let name = copiedItem.name {
            item.setString(name, forType: .string)
        }
        pasteBoard.declareTypes([type, .string], owner: nil)
        pasteBoard.writeObjects([item])

        copiedItem.updateDate = Date()
        persistenceController.persists()
        updateCopiedItems()
    }
    
    func favoriteButtonDidTap(_ copiedItem: CopiedItem) {
        copiedItem.favorite.toggle()
        persistenceController.persists()
        updateCopiedItems()
    }
    
    func deleteButtonDidTap(_ copiedItem: CopiedItem) {
        persistenceController.delete(copiedItem)
        updateCopiedItems()
    }

    func clearAll() {
        persistenceController.clearAllItems()
        updateCopiedItems()
    }
}

private class PersistenceController: ObservableObject {
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

    func createCopiedItem() -> CopiedItem {
        .init(context: container.viewContext)
    }

    func getSavedCopiedItems(with name: String? = nil, isShowingOnlyFavorite: Bool = false) -> [CopiedItem] {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        var updateDateSort = SortDescriptor<CopiedItem>(\.updateDate)
        var predicate: NSPredicate?
        if isShowingOnlyFavorite {
            predicate = NSPredicate(format: "favorite == YES")
        }
        
        if let name = name, !name.isEmpty {
            let searchTextPredicate = NSPredicate(format: "name Contains[c] %@", arguments: getVaList([name]))
            predicate = predicate.flatMap{NSCompoundPredicate(andPredicateWithSubpredicates: [searchTextPredicate, $0])} ?? searchTextPredicate
        }
        fetchRequest.predicate = predicate
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
        items.filter{ !$0.favorite }.forEach {
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
