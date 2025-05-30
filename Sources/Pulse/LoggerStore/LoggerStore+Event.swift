// The MIT License (MIT)
//
// 

import Foundation

public extension LoggerStore {
    /// The events used for syncing data between stores.
    @frozen enum Event: Sendable {
        case messageStored(MessageCreated)
        case networkTaskCreated(NetworkTaskCreated)
        case networkTaskProgressUpdated(NetworkTaskProgressUpdated)
        case networkTaskCompleted(NetworkTaskCompleted)

        public struct MessageCreated: Codable, Sendable {
            public var createdAt: Date
            public var label: String
            public var level: LoggerStore.Level
            public var message: String
            public var metadata: [String: String]?
            public var file: String
            public var function: String
            public var line: UInt

            @available(*, deprecated, message: "Deprecated (added for backward compatibility)")
            public var session: UUID? = Session.current.id

            public init(createdAt: Date, label: String, level: LoggerStore.Level, message: String, metadata: [String: String]?, file: String, function: String, line: UInt) {
                self.createdAt = createdAt
                self.label = label
                self.level = level
                self.message = message
                self.metadata = metadata
                self.file = file
                self.function = function
                self.line = line
            }

            init(_ entity: LoggerMessageEntity) {
                createdAt = entity.createdAt
                label = entity.label
                level = LoggerStore.Level(rawValue: entity.level) ?? .debug
                message = entity.text
                metadata = entity.metadata
                file = entity.file
                function = entity.function
                line = UInt(entity.line)
            }
        }

        public struct NetworkTaskCreated: Codable, Sendable, NetworkTaskEvent {
            public var taskId: UUID
            public var taskType: NetworkLogger.TaskType
            public var createdAt: Date
            public var originalRequest: NetworkLogger.Request
            public var currentRequest: NetworkLogger.Request?
            public var label: String?
            public var taskDescription: String?

            @available(*, deprecated, message: "Deprecated (added for backward compatibility)")
            public var session: UUID? = Session.current.id

            public init(taskId: UUID, taskType: NetworkLogger.TaskType, createdAt: Date, originalRequest: NetworkLogger.Request, currentRequest: NetworkLogger.Request?, label: String?, taskDescription: String?) {
                self.taskId = taskId
                self.taskType = taskType
                self.createdAt = createdAt
                self.originalRequest = originalRequest
                self.currentRequest = currentRequest
                self.label = label
                self.taskDescription = taskDescription
            }
        }

        public struct NetworkTaskProgressUpdated: Codable, Sendable {
            public var taskId: UUID
            public var url: URL?
            public var completedUnitCount: Int64
            public var totalUnitCount: Int64

            public init(taskId: UUID, url: URL?, completedUnitCount: Int64, totalUnitCount: Int64) {
                self.taskId = taskId
                self.url = url
                self.completedUnitCount = completedUnitCount
                self.totalUnitCount = totalUnitCount
            }
        }

        public struct NetworkTaskCompleted: Codable, Sendable, NetworkTaskEvent {
            public var taskId: UUID
            public var taskType: NetworkLogger.TaskType
            public var createdAt: Date
            public var originalRequest: NetworkLogger.Request
            public var currentRequest: NetworkLogger.Request?
            public var response: NetworkLogger.Response?
            public var error: NetworkLogger.ResponseError?
            public var requestBody: Data?
            public var responseBody: Data?
            public var metrics: NetworkLogger.Metrics?
            public var label: String?
            public var taskDescription: String?

            @available(*, deprecated, message: "Deprecated (added for backward compatibility)")
            public var session: UUID? = Session.current.id

            public init(taskId: UUID, taskType: NetworkLogger.TaskType, createdAt: Date, originalRequest: NetworkLogger.Request, currentRequest: NetworkLogger.Request?, response: NetworkLogger.Response?, error: NetworkLogger.ResponseError?, requestBody: Data?, responseBody: Data?, metrics: NetworkLogger.Metrics?, label: String?, taskDescription: String?) {
                self.taskId = taskId
                self.taskType = taskType
                self.createdAt = createdAt
                self.originalRequest = originalRequest
                self.currentRequest = currentRequest
                self.response = response
                self.error = error
                self.requestBody = requestBody
                self.responseBody = responseBody
                self.metrics = metrics
                self.label = label
                self.taskDescription = taskDescription
            }

            init(_ entity: NetworkTaskEntity) {
                taskId = entity.taskId
                taskType = NetworkLogger.TaskType(rawValue: entity.taskType) ?? .dataTask
                createdAt = entity.createdAt
                originalRequest = (entity.currentRequest.map(NetworkLogger.Request.init)) ?? .init(.init())
                currentRequest = entity.currentRequest.map(NetworkLogger.Request.init)
                response = entity.response.map(NetworkLogger.Response.init)
                error = entity.error.map(NetworkLogger.ResponseError.init)
                requestBody = entity.requestBody?.data
                responseBody = entity.responseBody?.data
                if entity.hasMetrics, let interval = entity.taskInterval {
                    let transactions = entity.orderedTransactions.map {
                        NetworkLogger.TransactionMetrics($0)
                    }
                    metrics = NetworkLogger.Metrics(taskInterval: interval, redirectCount: Int(entity.redirectCount), transactions: transactions)
                }
                label = entity.message?.label
                taskDescription = entity.taskDescription
            }
        }

        var url: URL? {
            switch self {
            case .messageStored:
                return nil
            case let .networkTaskCreated(event):
                return event.originalRequest.url
            case let .networkTaskProgressUpdated(event):
                return event.url
            case let .networkTaskCompleted(event):
                return event.originalRequest.url
            }
        }
    }
}

protocol NetworkTaskEvent {
    var taskId: UUID { get }
    var taskType: NetworkLogger.TaskType { get }
    var createdAt: Date { get }
    var label: String? { get }
    var originalRequest: NetworkLogger.Request { get }
    var taskDescription: String? { get }
}
