// The MIT License (MIT)
//
// 

import Foundation
import Pulse

/// Filter the logs displayed in the console.
struct ConsoleFilters: Hashable {
    var shared = Shared()
    var messages = Messages()
    var network = Network()

    struct Shared: Hashable {
        var sessions = Sessions()
        var dates = Dates()
    }

    struct Messages: Hashable {
        var logLevels = LogLevels()
        var labels = Labels()
    }

    struct Network: Hashable {
        var host = Host()
        var url = URL()
    }
}

protocol ConsoleFilterProtocol: Hashable {
    init() // Initializes with the default values
}

extension ConsoleFilters {
    struct Sessions: Hashable, ConsoleFilterProtocol {
        var selection: Set<UUID> = []
    }

    struct Dates: Hashable, ConsoleFilterProtocol {
        var startDate: Date?
        var endDate: Date?

        static var today: Dates {
            Dates(startDate: Calendar.current.startOfDay(for: Date()))
        }

        static var recent: Dates {
            Dates(startDate: Date().addingTimeInterval(-1200))
        }
    }

    struct LogLevels: ConsoleFilterProtocol {
          /// 默认改成 这几个,避免卡死页面
          var levels: Set<LoggerStore.Level> = Set([LoggerStore.Level.warning,LoggerStore.Level.error,LoggerStore.Level.critical])
              .subtracting([LoggerStore.Level.trace])
      }

    struct Labels: ConsoleFilterProtocol {
        var hidden: Set<String> = []
        var focused: String?
    }

    struct Host: ConsoleFilterProtocol {
        var hidden: Set<String> = []
        var focused: String?
    }

    struct URL: ConsoleFilterProtocol {
        var hidden: Set<String> = []
        var focused: String?
    }
}
