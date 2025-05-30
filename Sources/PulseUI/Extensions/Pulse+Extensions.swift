// The MIT License (MIT)
//
// 

import CoreData
import Foundation
import Pulse
import SwiftUI

enum LoggerEntity {
    /// Regular log, not task attached.
    case message(LoggerMessageEntity)
    /// Either a log with an attached task, or a task itself.
    case task(NetworkTaskEntity)

    init(_ entity: NSManagedObject) {
        if let message = entity as? LoggerMessageEntity {
            if let task = message.task {
                self = .task(task)
            } else {
                self = .message(message)
            }
        } else if let task = entity as? NetworkTaskEntity {
            self = .task(task)
        } else {
            fatalError("Unsupported entity: \(entity)")
        }
    }

    var task: NetworkTaskEntity? {
        if case let .task(task) = self { return task }
        return nil
    }
}

extension LoggerMessageEntity {
    var logLevel: LoggerStore.Level {
        LoggerStore.Level(rawValue: level) ?? .debug
    }
}

extension NetworkTaskEntity.State {
    var tintColor: Color {
        switch self {
        case .pending: return .orange
        case .success: return .green
        case .failure: return .red
        }
    }

    var iconSystemName: String {
        switch self {
        case .pending: return "clock.fill"
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.octagon.fill"
        }
    }
}

extension LoggerSessionEntity {
    var formattedDate: String {
        formattedDate(isCompact: false)
    }

    var searchTags: [String] {
        possibleFormatters.map { $0.string(from: createdAt) }
    }

    func formattedDate(isCompact: Bool = false) -> String {
        if isCompact {
            return compactDateFormatter.string(from: createdAt)
        } else {
            return fullDateFormatter.string(from: createdAt)
        }
    }

    var fullVersion: String? {
        guard let version = version else {
            return nil
        }
        if let build = build {
            return version + " (\(build))"
        }
        return version
    }
}

private let compactDateFormatter = DateFormatter(dateStyle: .none, timeStyle: .medium)

#if os(watchOS)
    private let fullDateFormatter = DateFormatter(dateStyle: .short, timeStyle: .short, isRelative: true)
#else
    private let fullDateFormatter = DateFormatter(dateStyle: .medium, timeStyle: .medium, isRelative: true)
#endif

private let possibleFormatters: [DateFormatter] = [
    fullDateFormatter,
    DateFormatter(dateStyle: .long, timeStyle: .none),
    DateFormatter(dateStyle: .short, timeStyle: .none),
]

#if !os(watchOS)

    extension NetworkTaskEntity {
        func cURLDescription() -> String {
            guard let request = currentRequest ?? originalRequest,
                  let url = request.url
            else {
                return "$ curl command generation failed"
            }

            var components = ["curl -v"]

            components.append("-X \(request.httpMethod ?? "GET")")

            for header in request.headers {
                let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
                components.append("-H \"\(header.key): \(escapedValue)\"")
            }

            if let httpBodyData = requestBody?.data {
                let httpBody = String(decoding: httpBodyData, as: UTF8.self)
                var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
                escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
                components.append("-d \"\(escapedBody)\"")
            }

            components.append("\"\(url)\"")

            return components.joined(separator: " \\\n\t")
        }
    }

#endif
