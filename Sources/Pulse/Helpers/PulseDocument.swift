// The MIT License (MIT)
//
// 

import CoreData

final class PulseDocument {
    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }

    init(documentURL: URL) throws {
        guard Files.fileExists(atPath: documentURL.deletingLastPathComponent().path) else {
            throw LoggerStore.Error.fileDoesntExist
        }
        container = NSPersistentContainer(name: documentURL.lastPathComponent, managedObjectModel: PulseDocument.model)
        let store = NSPersistentStoreDescription(url: documentURL)
        store.setValue("OFF" as NSString, forPragmaNamed: "journal_mode")
        container.persistentStoreDescriptions = [store]

        try container.loadStore()
    }

    func close() throws {
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
        }
    }

    /// - warning: Model has to be loaded only once.
    static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        let blob = NSEntityDescription(class: PulseBlobEntity.self)
        blob.properties = [
            NSAttributeDescription(name: "key", type: .stringAttributeType),
            NSAttributeDescription(name: "data", type: .binaryDataAttributeType),
        ]
        model.entities = [blob]
        return model
    }()
}

final class PulseBlobEntity: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var data: Data
}
