//
//  CopiedItemRepository.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/08/27.
//

import Foundation
import CoreData
import Combine
import AppKit

class CopiedItemRepository {

    lazy var stream: AsyncStream<[CopiedItem]>? = {
        return AsyncStream<[CopiedItem]> { [weak self] continuation in
            self?.delegate = FetchedResultsControllerDelegateWrapper(continuation: continuation)
            self?.fetchedResultController.delegate = self?.delegate
        }
    }()

    private lazy var _copiedItems: CurrentValueSubject<[CopiedItem], Never> = .init(fetchedResultController.fetchedObjects ?? [])
    private let coreDataService: CoreDataService = .init()

    private var delegate: FetchedResultsControllerDelegateWrapper<[CopiedItem]>?

    init() {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        fetchRequest.fetchLimit = 30
        var updateDateSort = SortDescriptor<CopiedItem>(\.updateDate)
        updateDateSort.order = .reverse
        fetchRequest.sortDescriptors = [NSSortDescriptor(updateDateSort)]
        fetchedResultController =  coreDataService.makeFetchedResultController(request: fetchRequest)

    }

    private var fetchedResultController: NSFetchedResultsController<CopiedItem>

    var copiedItems: [CopiedItem] {
        fetchedResultController.fetchedObjects ?? []
    }

    func requestCopiedItems(
        with text: String? = nil,
        isShowingOnlyFavorite: Bool = false,
        isShowingOnlyMemoed: Bool = false,
        isShowingOnlyReminder: Bool = false,
        sort: ItemSort = ItemSort(),
        limit: Int? = nil
    ) {
        request(
            with: makeCopiedItemsRequest(with: text,
                                         isShowingOnlyFavorite: isShowingOnlyFavorite,
                                         isShowingOnlyMemoed: isShowingOnlyMemoed,
                                         isShowingOnlyReminder: isShowingOnlyReminder,
                                         sort: sort,
                                         limit: limit)
        )
    }

    /// Every saved item (favorites included), newest first, without the binary payload.
    func fetchAllForExport() throws -> [CopiedItem] {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        fetchRequest.propertiesToFetch = ["binarySize", "contentTypeString", "createdDate", "favorite", "memo", "name", "rawString", "reminderDate", "updateDate"]
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updateDate", ascending: false)]
        return try coreDataService.fetch(fetchRequest)
    }

    /// Fills attributes added after the first release for items saved before them.
    func backfillMissingAttributes() {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        fetchRequest.predicate = NSPredicate(format: "createdDate == nil OR (textLength == 0 AND rawString != nil AND rawString != '')")
        do {
            let items = try coreDataService.fetch(fetchRequest)
            guard !items.isEmpty else { return }
            items.forEach { item in
                if item.createdDate == nil { item.createdDate = item.updateDate }
                if item.textLength == 0 { item.textLength = Int64(item.rawString?.count ?? 0) }
            }
            try coreDataService.saveOrRollback()
        } catch {
            NSLog("Failed to backfill item attributes: \(error) \((error as NSError).userInfo)")
        }
    }

    /// Text items for the AI filter: every saved item that matches the current filters, capped by `limit`.
    func fetchTextItems(
        with text: String?,
        isShowingOnlyFavorite: Bool,
        isShowingOnlyMemoed: Bool,
        isShowingOnlyReminder: Bool,
        sort: ItemSort,
        limit: Int
    ) throws -> [CopiedItem] {
        let request = makeCopiedItemsRequest(with: text,
                                             isShowingOnlyFavorite: isShowingOnlyFavorite,
                                             isShowingOnlyMemoed: isShowingOnlyMemoed,
                                             isShowingOnlyReminder: isShowingOnlyReminder,
                                             sort: sort,
                                             limit: limit)
        let hasText = NSPredicate(format: "rawString != nil AND rawString != ''")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [request.predicate, hasText].compactMap { $0 })
        return try coreDataService.fetch(request)
    }

    /// The newest image whose text has not been read yet.
    func nextImageNeedingOCR() -> CopiedItem? {
        let request = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        let imageTypes = ["image", "png", "jpeg", "tiff", "gif", "bmp"]
            .map { "contentTypeString CONTAINS[c] '\($0)'" }
            .joined(separator: " OR ")
        request.predicate = NSPredicate(format: "ocrText == nil AND (\(imageTypes))")
        request.sortDescriptors = [NSSortDescriptor(key: "updateDate", ascending: false)]
        request.fetchLimit = 1
        return coreDataService.getObject(from: request)
    }

    func create() -> CopiedItem {
        coreDataService.create(type: CopiedItem.self)
    }

    func getItem(hash: String) -> CopiedItem? {
        coreDataService.getObject(from: makeCopiedItemRequest(from: hash))
    }

    func update() {
        coreDataService.save()
    }

    func delete(object: NSManagedObject) {
        coreDataService.delete(target: object)
    }

    func deleteAll() {
        coreDataService.deleteAll(targets: _copiedItems.value.filter { !$0.favorite })
    }

    private func request(with request: NSFetchRequest<CopiedItem>) {

        guard  delegate != nil else {
            return
        }

        if request.fetchLimit != fetchedResultController.fetchRequest.fetchLimit {

            // FetchLimitは後から変更できないのでFetchLimitが変わったときはfetchedResultControllerごと変更する。
            fetchedResultController =  coreDataService.makeFetchedResultController(request: request)
            fetchedResultController.delegate = delegate
        } else {
            fetchedResultController.fetchRequest.predicate = request.predicate
            fetchedResultController.fetchRequest.sortDescriptors = request.sortDescriptors
        }

        do {
            try fetchedResultController.managedObjectContext.performAndWait {
                try fetchedResultController.performFetch()
            }
        } catch {
            assertionFailure("failed for \(request)")
        }

    }

    private func makeCopiedItemsRequest(with text: String? = nil, isShowingOnlyFavorite: Bool = false, isShowingOnlyMemoed: Bool = false, isShowingOnlyReminder: Bool = false, sort: ItemSort = ItemSort(), limit: Int? = nil) -> NSFetchRequest<CopiedItem> {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.propertiesToFetch = ["binarySize", "contentTypeString", "createdDate", "dataHash", "favorite", "memo", "name", "ocrText", "rawString", "reminderDate", "textLength", "updateDate"]

        var favoritePredicate: NSPredicate?
        if isShowingOnlyFavorite {
            favoritePredicate = NSPredicate(format: "favorite == YES")
        }
        var memoedPredicate: NSPredicate?
        if isShowingOnlyMemoed {
            memoedPredicate = NSPredicate(format: "NOT (memo == %@ OR memo == nil OR memo == '')")
        }
        var reminderPredicate: NSPredicate?
        if isShowingOnlyReminder {
            reminderPredicate = NSPredicate(format: "reminderDate != nil")
        }
        var textPredicate: NSPredicate?
        if let text = text, !text.isEmpty {
            textPredicate = NSPredicate(format: "contentTypeString Contains[c] %@ OR rawString Contains[c] %@ OR name Contains[c] %@ OR memo Contains[c] %@ OR ocrText Contains[c] %@", arguments: getVaList([text, text, text, text, text]))
        }

        let predicate: NSPredicate? = NSCompoundPredicate(andPredicateWithSubpredicates: [textPredicate, favoritePredicate, memoedPredicate, reminderPredicate].compactMap { $0 })
        fetchRequest.predicate = predicate

        if let limit {
            fetchRequest.fetchLimit = limit
        }
        if isShowingOnlyReminder {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "reminderDate", ascending: true)]
        } else {
            fetchRequest.sortDescriptors = sort.sortDescriptors
        }
        return fetchRequest
    }

    private func makeCopiedItemRequest(from hash: String) -> NSFetchRequest<CopiedItem> {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        let predicate = NSPredicate(format: "dataHash == %@", arguments: getVaList([hash]))
        fetchRequest.predicate = predicate
        return fetchRequest
    }
}
