// The MIT License (MIT)
//
// 

#if os(iOS) || os(macOS) || os(watchOS) || os(visionOS)

    import Combine
    import CoreData
    import Pulse
    import SwiftUI

    @MainActor final class ShareStoreViewModel: ObservableObject {
        // Sharing options
        @Published var sessions: Set<UUID> = []
        @Published var logLevels = Set(LoggerStore.Level.allCases)
        let shareStoreOutputs: [ShareStoreOutput]
        @Published var output: ShareStoreOutput

        @Published private(set) var isPreparingForSharing = false
        @Published private(set) var errorMessage: String?
        @Published var shareItems: ShareItems?

        @ObservedObject private var settings: UserSettings = .shared

        var store: LoggerStore?

        init() {
            var outputs = UserSettings.shared.allowedShareStoreOutputs
            if outputs.isEmpty {
                outputs = ShareStoreOutput.allCases
            }
            if outputs.contains(UserSettings.shared.sharingOutput) {
                output = UserSettings.shared.sharingOutput
            } else {
                output = outputs[0]
            }
            shareStoreOutputs = outputs
        }

        func buttonSharedTapped() {
            guard !isPreparingForSharing else { return }
            isPreparingForSharing = true
            saveSharingOptions()
            prepareForSharing()
        }

        private func saveSharingOptions() {
            UserSettings.shared.sharingOutput = output
        }

        func prepareForSharing() {
            guard let store = store else { return }

            isPreparingForSharing = true
            shareItems = nil
            errorMessage = nil

            Task {
                do {
                    let options = LoggerStore.ExportOptions(predicate: predicate, sessions: sessions)
                    self.shareItems = try await prepareForSharing(store: store, options: options)
                } catch {
                    guard !(error is CancellationError) else { return }
                    self.errorMessage = error.localizedDescription
                }
                self.isPreparingForSharing = false
            }
        }

        var selectedLevelsTitle: String {
            if logLevels.count == 1 {
                return logLevels.first!.name.capitalized
            } else if logLevels.count == 0 {
                return "–"
            } else if logLevels == [.error, .critical] {
                return "Errors"
            } else if logLevels == [.warning, .error, .critical] {
                return "Warnings & Errors"
            } else if logLevels.count == LoggerStore.Level.allCases.count {
                return "All"
            } else {
                return "\(logLevels.count)"
            }
        }

        private var predicate: NSPredicate? {
            var predicates: [NSPredicate] = []
            if logLevels != Set(LoggerStore.Level.allCases) {
                predicates.append(.init(format: "level IN %@", logLevels.map(\.rawValue)))
            }
            if !sessions.isEmpty {
                predicates.append(.init(format: "session IN %@", sessions))
            }
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        private func prepareForSharing(store: LoggerStore, options: LoggerStore.ExportOptions) async throws -> ShareItems {
            switch output {
            case .store:
                return try await prepareStoreForSharing(store: store, options: options)
            case .text, .html:
                let output: ShareOutput = output == .text ? .plainText : .html
                return try await prepareForSharing(store: store, output: output, options: options)
            case .har:
                return try await prepareForSharing(store: store, output: .har, options: options)
            }
        }

        private func prepareStoreForSharing(store: LoggerStore, options: LoggerStore.ExportOptions) async throws -> ShareItems {
            let directory = TemporaryDirectory()

            let logsURL = directory.url.appendingPathComponent("logs-\(makeCurrentDate()).\(output.fileExtension)")
            try await store.export(to: logsURL, options: options)
            return ShareItems([logsURL], cleanup: directory.remove)
        }

        private func prepareForSharing(store: LoggerStore, output: ShareOutput, options: LoggerStore.ExportOptions) async throws -> ShareItems {
            let entities = try await withUnsafeThrowingContinuation { continuation in
                store.backgroundContext.perform {
                    let request = NSFetchRequest<LoggerMessageEntity>(entityName: "\(LoggerMessageEntity.self)")
                    request.predicate = options.predicate // important: contains sessions

                    let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
                    request.sortDescriptors = [sortDescriptor]

                    let result = Result(catching: { try store.backgroundContext.fetch(request) })
                    continuation.resume(with: result)
                }
            }
            return try await ShareService.share(entities, store: store, as: output)
        }
    }

#endif
