//
//  CoreDataService.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/08/27.
//

import Foundation
import CoreData
import AppKit

class FetchedResultsControllerDelegateWrapper<T>: NSObject, NSFetchedResultsControllerDelegate {
    let continuation: AsyncStream<T>.Continuation
    init(continuation: AsyncStream<T>.Continuation) {
        self.continuation = continuation
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        if let fetchedObjects = controller.fetchedObjects as? T {
            continuation.yield(fetchedObjects)
        }
    }
}

class CoreDataService {
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

    // MARK: - CRD

    func makeFetchedResultController<T>(request: NSFetchRequest<T>) -> NSFetchedResultsController<T> {
        return .init(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }

    func create<T: NSManagedObject>(type: T.Type) -> T {
        type.init(context: container.viewContext)
    }

    func getObject<T: NSManagedObject>(from request: NSFetchRequest<T>) -> T? {
        (try? container.viewContext.fetch(request))?.first
    }

    func save() {
        try! container.viewContext.save()

    }

    func deleteAll(targets: [NSManagedObject]) {
        targets.forEach {
            container.viewContext.delete($0)
        }
        try? container.viewContext.save()
    }

    func delete(target: NSManagedObject) {
        container.viewContext.delete(target)
        try? container.viewContext.save()

    }

}
