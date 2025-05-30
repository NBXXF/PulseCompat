// The MIT License (MIT)
//
// 

import Combine
import CoreData
import Foundation
import Pulse

/// Keeps track of hosts, paths, etc.
final class LoggerStoreIndex: ObservableObject {
    @Published private(set) var labels: Set<String> = []
    @Published private(set) var files: Set<String> = []
    @Published private(set) var hosts: Set<String> = []
    @Published private(set) var paths: Set<String> = []

    private let context: NSManagedObjectContext
    private var cancellable: AnyCancellable?

    convenience init(store: LoggerStore) {
        self.init(context: store.backgroundContext)

        store.backgroundContext.perform {
            self.prepopulate()
        }
        cancellable = store.events.receive(on: DispatchQueue.main).sink { [weak self] in
            self?.handle($0)
        }
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        context.perform {
            self.prepopulate()
        }
    }

    private func handle(_ event: LoggerStore.Event) {
        switch event {
        case let .messageStored(event):
            files.insert(event.file)
            labels.insert(event.label)
        case let .networkTaskCompleted(event):
            if let host = event.originalRequest.url.flatMap(getHost) {
                var hosts = self.hosts
                let (isInserted, _) = hosts.insert(host)
                if isInserted { self.hosts = hosts }
            }
        default:
            break
        }
    }

    private func prepopulate() {
        let files = context.getDistinctValues(entityName: "LoggerMessageEntity", property: "file")
        let labels = context.getDistinctValues(entityName: "LoggerMessageEntity", property: "label")
        let urls = context.getDistinctValues(entityName: "NetworkTaskEntity", property: "url")

        var hosts = Set<String>()
        var paths = Set<String>()

        for url in urls {
            guard let components = URLComponents(string: url) else {
                continue
            }
            if let host = components.host, !host.isEmpty {
                hosts.insert(host)
            }
            paths.insert(components.path)
        }

        DispatchQueue.main.async {
            self.labels = labels
            self.files = files
            self.hosts = hosts
            self.paths = paths
        }
    }

    func clear() {
        labels = []
        files = []
        paths = []
        hosts = []
    }
}

private func getHost(for url: URL) -> String? {
    if let host = url.host {
        return host
    }
    if url.scheme == nil, let url = URL(string: "https://" + url.absoluteString) {
        return url.host ?? "" // URL(string: "example.com")?.host with not scheme returns host: ""
    }
    return nil
}
