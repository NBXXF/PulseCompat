// The MIT License (MIT)
//
// 

import CoreData
import Foundation
import Pulse

extension ConsoleFilters {
    static func makeMessagePredicates(
        criteria: ConsoleFilters,
        isOnlyErrors: Bool
    ) -> NSPredicate? {
        var predicates = [NSPredicate]()
        if isOnlyErrors {
            predicates.append(NSPredicate(format: "level IN %@", [LoggerStore.Level.critical, .error].map { $0.rawValue }))
        }
        predicates += makePredicates(for: criteria.shared)
        predicates += makePredicates(for: criteria.messages)
        return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static func makeNetworkPredicates(
        criteria: ConsoleFilters,
        isOnlyErrors: Bool
    ) -> NSPredicate? {
        var predicates = [NSPredicate]()
        if isOnlyErrors {
            predicates.append(NSPredicate(format: "requestState == %d", NetworkTaskEntity.State.failure.rawValue))
        }
        predicates += makePredicates(for: criteria.shared, isNetwork: true)
        predicates += makePredicates(for: criteria.network)
        return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

private func makePredicates(for criteria: ConsoleFilters.Shared, isNetwork _: Bool = false) -> [NSPredicate] {
    var predicates = [NSPredicate]()

    if !criteria.sessions.selection.isEmpty {
        predicates.append(NSPredicate(format: "session IN %@", criteria.sessions.selection))
    }

    if let startDate = criteria.dates.startDate {
        predicates.append(NSPredicate(format: "createdAt >= %@", startDate as NSDate))
    }
    if let endDate = criteria.dates.endDate {
        predicates.append(NSPredicate(format: "createdAt <= %@", endDate as NSDate))
    }

    return predicates
}

private func makePredicates(for criteria: ConsoleFilters.Messages) -> [NSPredicate] {
    var predicates = [NSPredicate]()

    if criteria.logLevels.levels.count != LoggerStore.Level.allCases.count {
        predicates.append(NSPredicate(format: "level IN %@", Array(criteria.logLevels.levels.map { $0.rawValue })))
    }

    if let focusedLabel = criteria.labels.focused {
        predicates.append(NSPredicate(format: "label == %@", focusedLabel))
    } else if !criteria.labels.hidden.isEmpty {
        predicates.append(NSPredicate(format: "NOT label IN %@", Array(criteria.labels.hidden)))
    }

    return predicates
}

private func makePredicates(for criteria: ConsoleFilters.Network) -> [NSPredicate] {
    var predicates = [NSPredicate]()

    if let focusedHost = criteria.host.focused {
        predicates.append(NSPredicate(format: "host == %@", focusedHost))
    } else if !criteria.host.hidden.isEmpty {
        predicates.append(NSPredicate(format: "NOT host IN %@", Array(criteria.host.hidden)))
    }

    if let focusedURL = criteria.url.focused {
        predicates.append(NSPredicate(format: "url == %@", focusedURL))
    } else if !criteria.url.hidden.isEmpty {
        predicates.append(NSPredicate(format: "NOT url IN %@", Array(criteria.url.hidden)))
    }

    return predicates
}
