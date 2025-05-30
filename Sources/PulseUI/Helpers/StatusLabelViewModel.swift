// The MIT License (MIT)
//
// 

import Foundation
import Pulse
import SwiftUI

struct StatusLabelViewModel {
    let systemImage: String
    let tint: Color
    let title: String

    init(task: NetworkTaskEntity, store: LoggerStore?) {
        guard let state = task.state(in: store) else {
            systemImage = "questionmark.diamond.fill"
            tint = .secondary
            title = "Unknown"
            return
        }
        switch state {
        case .pending:
            systemImage = "clock.fill"
            tint = .orange
            title = ProgressViewModel.title(for: task)
        case .success:
            systemImage = "checkmark.circle.fill"
            tint = .green
            title = StatusCodeFormatter.string(for: Int(task.statusCode))
        case .failure:
            systemImage = "exclamationmark.octagon.fill"
            tint = .red
            title = ErrorFormatter.shortErrorDescription(for: task)
        }
    }

    init(transaction: NetworkTransactionMetricsEntity) {
        if let response = transaction.response {
            if response.isSuccess {
                systemImage = "checkmark.circle.fill"
                title = StatusCodeFormatter.string(for: Int(response.statusCode))
                tint = .green
            } else {
                systemImage = "exclamationmark.octagon.fill"
                title = StatusCodeFormatter.string(for: Int(response.statusCode))
                tint = .red
            }
        } else {
            systemImage = "exclamationmark.octagon.fill"
            title = "No Response"
            tint = .secondary
        }
    }

    var text: Text {
        (Text(Image(systemName: systemImage)) + Text(" " + title))
            .foregroundColor(tint)
    }
}

private extension NetworkResponseEntity {
    var isSuccess: Bool {
        (100 ..< 400).contains(statusCode)
    }
}
