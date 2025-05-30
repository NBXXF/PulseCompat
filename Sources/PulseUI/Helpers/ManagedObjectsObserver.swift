// The MIT License (MIT)
//
// 

import Combine
import CoreData
import Foundation
import Pulse
import SwiftUI

final class ManagedObjectsObserver<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    @Published private(set) var objects: [T] = []

    private let controller: NSFetchedResultsController<T>

    init(request: NSFetchRequest<T>,
         context: NSManagedObjectContext,
         cacheName: String? = nil)
    {
        controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: cacheName)
        super.init()

        try? controller.performFetch()
        objects = controller.fetchedObjects ?? []

        controller.delegate = self
    }

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        objects = controller.fetchedObjects ?? []
    }
}

extension ManagedObjectsObserver where T == LoggerSessionEntity {
    static func sessions(for context: NSManagedObjectContext) -> ManagedObjectsObserver {
        let request = NSFetchRequest<LoggerSessionEntity>(entityName: "\(LoggerSessionEntity.self)")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LoggerSessionEntity.createdAt, ascending: false)]

        return ManagedObjectsObserver(request: request, context: context, cacheName: "com.github.pulse.sessions-cache")
    }
}
