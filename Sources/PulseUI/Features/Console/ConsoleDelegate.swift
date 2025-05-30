// The MIT License (MIT)
//
// 

import Foundation
import Pulse

enum ConsoleViewDelegate {
    static func getTitle(for task: NetworkTaskEntity) -> String? {
        if let taskDescription = task.taskDescription, !taskDescription.isEmpty {
            return taskDescription
        }
        return task.url
    }

    static func getShortTitle(for task: NetworkTaskEntity) -> String {
        guard let title = getTitle(for: task) else {
            return ""
        }
        return URL(string: title)?.lastPathComponent ?? title
    }
}
