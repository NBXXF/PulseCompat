// The MIT License (MIT)
//
// 

import Combine
import Pulse
import SwiftUI

/// Allows you to control Pulse appearance and other settings programmatically.
public final class UserSettings: ObservableObject {
    public static let shared = UserSettings()

    /// The console default mode.
    @AppStorage("com.github.kean.pulse.console.mode")
    public var mode: ConsoleMode = .network

    /// The line limit for messages in the console. By default, `3`.
    @AppStorage("com.github.kean.pulse.consoleCellLineLimit")
    public var lineLimit: Int = 3

    /// Enables link detection in the response viewier. By default, `false`.
    @AppStorage("com.github.kean.pulse.linkDetection")
    public var isLinkDetectionEnabled = false

    /// The default sharing output type. By default, ``ShareStoreOutput/store``.
    @AppStorage("com.github.kean.pulse.sharingOutput")
    public var sharingOutput: ShareStoreOutput = .store

    /// HTTP headers to display in a Console. By default, empty.
    public var displayHeaders: [String] {
        get {
            let data = rawDisplayHeaders.data(using: .utf8) ?? Data()
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            rawDisplayHeaders = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    @AppStorage("com.github.kean.pulse.display.headers")
    var rawDisplayHeaders: String = "[]"

    /// If `true`, the network inspector will show the current request by default.
    /// If `false`, show the original request.
    @AppStorage("com.github.kean.pulse.showCurrentRequest")
    public var isShowingCurrentRequest = true

    /// The allowed sharing options.
    public var allowedShareStoreOutputs: [ShareStoreOutput] {
        get {
            let data = rawAllowedShareStoreOutputs.data(using: .utf8) ?? Data()
            return (try? JSONDecoder().decode([ShareStoreOutput].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            rawAllowedShareStoreOutputs = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    @AppStorage("com.github.kean.pulse.allowedShareStoreOutputs")
    var rawAllowedShareStoreOutputs: String = "[]"

    /// If enabled, the console stops showing the remote logging option.
    @AppStorage("com.github.kean.pulse.isRemoteLoggingAllowed")
    public var isRemoteLoggingHidden = false
}
