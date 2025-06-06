// The MIT License (MIT)
//
// 

import Combine
import CoreData
import Foundation
import Pulse
import SwiftUI

final class ConsoleListViewModel: ConsoleDataSourceDelegate, ObservableObject, ConsoleEntitiesSource {
    #if os(iOS) || os(visionOS) || os(macOS)
        @Published private(set) var visibleEntities: ArraySlice<NSManagedObject> = []
    #else
        var visibleEntities: [NSManagedObject] { entities }
    #endif
    @Published private(set) var entities: [NSManagedObject] = []
    @Published private(set) var sections: [NSFetchedResultsSectionInfo]?

    @Published private(set) var mode: ConsoleMode

    var isViewVisible = false {
        didSet {
            guard oldValue != isViewVisible else { return }
            if isViewVisible {
                resetDataSource(options: environment.listOptions)
            } else {
                dataSource = nil
            }
        }
    }

    @Published private(set) var previousSession: LoggerSessionEntity?

    let events = PassthroughSubject<ConsoleUpdateEvent, Never>()

    #if os(iOS) || os(visionOS) || os(macOS)
        /// This exist strictly to workaround List performance issues
        private var scrollPosition: ScrollPosition = .nearTop
        private var visibleEntityCountLimit = ConsoleDataSource.fetchBatchSize
        private var visibleObjectIDs: Set<NSManagedObjectID> = []
    #endif

    private let store: LoggerStore
    private let environment: ConsoleEnvironment
    private let filters: ConsoleFiltersViewModel
    private let sessions: ManagedObjectsObserver<LoggerSessionEntity>
    private var dataSource: ConsoleDataSource?
    private var cancellables: [AnyCancellable] = []
    private var filtersCancellable: AnyCancellable?

    init(environment: ConsoleEnvironment, filters: ConsoleFiltersViewModel) {
        store = environment.store
        self.environment = environment
        mode = environment.mode
        self.filters = filters
        sessions = .sessions(for: store.viewContext)

        $entities.sink { [weak self] in
            self?.filters.entities.send($0)
        }.store(in: &cancellables)

        sessions.$objects.dropFirst().sink { [weak self] in
            self?.refreshPreviousSessionButton(sessions: $0)
        }.store(in: &cancellables)

        environment.$listOptions.dropFirst().sink { [weak self] in
            self?.resetDataSource(options: $0)
        }.store(in: &cancellables)

        environment.$mode.sink { [weak self] in
            self?.didUpdateMode($0)
        }.store(in: &cancellables)
    }

    private func didUpdateMode(_ mode: ConsoleMode) {
        self.mode = mode
        if isViewVisible {
            resetDataSource(options: environment.listOptions)
        }
    }

    private func resetDataSource(options: ConsoleListOptions) {
        dataSource = ConsoleDataSource(store: store, mode: mode, options: options)
        dataSource?.delegate = self
        filtersCancellable = filters.$options.sink { [weak self] in
            self?.dataSource?.predicate = $0
        }
    }

    func buttonShowPreviousSessionTapped(for session: LoggerSessionEntity) {
        filters.criteria.shared.sessions.selection.insert(session.id)
        refreshPreviousSessionButton(sessions: sessions.objects)
    }

    private func refreshPreviousSessionButton(sessions: [LoggerSessionEntity]) {
        let selection = filters.criteria.shared.sessions.selection
        let isDisplayingPrefix = sessions.prefix(selection.count).allSatisfy {
            selection.contains($0.id)
        }
        guard isDisplayingPrefix,
              sessions.count > selection.count
        else {
            previousSession = nil
            return
        }
        previousSession = sessions[selection.count]
    }

    // MARK: ConsoleDataSourceDelegate

    func dataSourceDidRefresh(_ dataSource: ConsoleDataSource) {
        guard isViewVisible else { return }

        entities = dataSource.entities
        #if os(iOS) || os(visionOS) || os(macOS)
            refreshVisibleEntities()
        #endif
        events.send(.refresh)
    }

    func dataSource(_ dataSource: ConsoleDataSource, didUpdateWith diff: CollectionDifference<NSManagedObjectID>?) {
        entities = dataSource.entities
        #if os(iOS) || os(visionOS) || os(macOS)
            if scrollPosition == .nearTop {
                refreshVisibleEntities()
            }
        #endif
        events.send(.update(diff))
    }

    // MARK: Visible Entities

    #if os(iOS) || os(visionOS) || os(macOS)
        private enum ScrollPosition {
            case nearTop
            case middle
            case nearBottom
        }

        func onDisappearCell(with objectID: NSManagedObjectID) {
            visibleObjectIDs.remove(objectID)
            refreshScrollPosition()
        }

        func onAppearCell(with objectID: NSManagedObjectID) {
            visibleObjectIDs.insert(objectID)
            refreshScrollPosition()
        }

        private func refreshScrollPosition() {
            let scrollPosition: ScrollPosition
            if visibleObjectIDs.isEmpty || visibleEntities.prefix(5).map(\.objectID).contains(where: visibleObjectIDs.contains) {
                scrollPosition = .nearTop
            } else if visibleEntities.suffix(5).map(\.objectID).contains(where: visibleObjectIDs.contains) {
                scrollPosition = .nearBottom
            } else {
                scrollPosition = .middle
            }

            guard scrollPosition != self.scrollPosition else {
                return
            }
            self.scrollPosition = scrollPosition
            switch scrollPosition {
            case .nearTop:
                DispatchQueue.main.async {
                    // Important: when we push a new screens all cells disappear
                    // and the state transitions to .nearTop. We don't want the
                    // view to reload when that happens.
                    if self.isViewVisible {
                        self.refreshVisibleEntities()
                    }
                }
            case .middle:
                break // Don't reload: too expensive and ruins gestures
            case .nearBottom:
                if visibleEntities.count < entities.count {
                    visibleEntityCountLimit += ConsoleDataSource.fetchBatchSize
                    refreshVisibleEntities()
                }
            }
        }

        private func refreshVisibleEntities() {
            visibleEntities = entities.prefix(visibleEntityCountLimit)
        }
    #endif
}
