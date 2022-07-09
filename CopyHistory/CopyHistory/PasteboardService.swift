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

    private let persistenceController = PersistenceController()
    private var pasteBoard: NSPasteboard { NSPasteboard.general }
    private var latestChangeCount = 0
    private lazy var timer: Timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)

    static func build() -> PasteboardService {
        let p = PasteboardService()
        p.initialize()
        return p
    }

    private init() {}

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
        copiedItems = persistenceController.getSavedCopiedItems(with: searchText)
    }

    private func initialize() {
        timer.fire()
        copiedItems = persistenceController.getSavedCopiedItems(with: searchText)
    }

    func deleteButtonDidTap(_ copiedItem: CopiedItem) {
        persistenceController.delete(copiedItem)
        copiedItems = persistenceController.getSavedCopiedItems(with: searchText)
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
        copiedItems = persistenceController.getSavedCopiedItems(with: searchText)
    }

    func search() {
        copiedItems = persistenceController.getSavedCopiedItems(with: searchText)
    }

    func clearAll() {
        persistenceController.clearAllItems()
        copiedItems = persistenceController.getSavedCopiedItems(with: searchText)
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

    func getSavedCopiedItems(with name: String? = nil) -> [CopiedItem] {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        var updateDateSort = SortDescriptor<CopiedItem>(\.updateDate)

        if let name = name, !name.isEmpty {
            let predicate = NSPredicate(format: "name Contains[c] %@", arguments: getVaList([name]))

            fetchRequest.predicate = predicate
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
        items.forEach {
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
