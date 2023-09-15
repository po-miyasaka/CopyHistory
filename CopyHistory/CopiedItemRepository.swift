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
        limit: Int? = nil
    ) {
        request(
            with: makeCopiedItemsRequest(with: text,
                                         isShowingOnlyFavorite: isShowingOnlyFavorite,
                                         isShowingOnlyMemoed: isShowingOnlyMemoed,
                                         limit: limit)
        )
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
        coreDataService.deleteAll(targets: _copiedItems.value.filter {$0.favorite})
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
        }

        do {
            try fetchedResultController.managedObjectContext.performAndWait {
                try fetchedResultController.performFetch()
            }
        } catch {
            assertionFailure("failed for \(request)")
        }

    }

    private func makeCopiedItemsRequest(with text: String? = nil, isShowingOnlyFavorite: Bool = false, isShowingOnlyMemoed: Bool = false, limit: Int? = nil) -> NSFetchRequest<CopiedItem> {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        fetchRequest.returnsObjectsAsFaults = true

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
        var updateDateSort = SortDescriptor<CopiedItem>(\.updateDate)
        updateDateSort.order = .reverse
        fetchRequest.sortDescriptors = [NSSortDescriptor(updateDateSort)]
        return fetchRequest
    }

    private func makeCopiedItemRequest(from hash: String) -> NSFetchRequest<CopiedItem> {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        let predicate = NSPredicate(format: "dataHash == %@", arguments: getVaList([hash]))
        fetchRequest.predicate = predicate
        return fetchRequest
    }
}
