// The MIT License (MIT)
//
// 

import Combine
import CoreData
import Pulse
import SwiftUI

public extension ConsoleView {
    /// Initializes the console view.
    ///
    /// - parameters:
    ///   - store: The store to display. By default, `LoggerStore/shared`.
    ///   - mode: The initial console mode. By default, ``ConsoleMode/all``. If you change
    ///   the mode to ``ConsoleMode/network``, the console will display the
    ///   network messages up on appearance.
    ///   - delegate: The delegate that allows you to customize multiple aspects
    ///   of the console view.
    init(
        store: LoggerStore = .shared,
        mode: ConsoleMode = .all
    ) {
        self.init(environment: .init(store: store, mode: mode))
    }
}
