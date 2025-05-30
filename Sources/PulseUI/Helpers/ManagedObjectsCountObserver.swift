// The MIT License (MIT)
//
// 

import CoreData

final class ManagedObjectsCountObserver: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    let controller: NSFetchedResultsController<NSManagedObject>

    @Published private(set) var count = 0

    init<T: NSManagedObject>(entity _: T.Type, context: NSManagedObjectContext, sortDescriptior: NSSortDescriptor) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "\(T.self)")
        request.fetchBatchSize = 1
        request.sortDescriptors = [sortDescriptior]

        controller = NSFetchedResultsController<NSManagedObject>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        super.init()

        controller.delegate = self
        refresh()
    }

    func setPredicate(_ predicate: NSPredicate?) {
        controller.fetchRequest.predicate = predicate
        refresh()
    }

    func refresh() {
        try? controller.performFetch()
        count = controller.fetchedObjects?.count ?? 0
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        count = controller.fetchedObjects?.count ?? 0
    }
}
