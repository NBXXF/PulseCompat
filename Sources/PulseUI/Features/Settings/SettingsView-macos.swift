// The MIT License (MIT)
//
// 

#if os(macOS)

    import Pulse
    import SwiftUI

    @available(macOS 13, *)
    struct SettingsView: View {
        @State private var isPresentingShareStoreView = false
        @State private var shareItems: ShareItems?

        @Environment(\.store) private var store
        @EnvironmentObject private var environment: ConsoleEnvironment

        var body: some View {
            List {
                if !UserSettings.shared.isRemoteLoggingHidden {
                    if store === RemoteLogger.shared.store {
                        RemoteLoggerSettingsView(viewModel: .shared)
                    } else {
                        Text("Not available")
                            .foregroundColor(.secondary)
                    }
                }
                Section {
                    // TODO: load this info async
//                if #available(macOS 13, *), let info = try? store.info() {
//                    LoggerStoreSizeChart(info: info, sizeLimit: store.configuration.sizeLimit)
//                }
                } header: {
                    PlainListSectionHeaderSeparator(title: "Store")
                }

                Section {
                    HStack {
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([store.storeURL])
                        }
                        if !(store.options.contains(.readonly)) {
                            Button("Remove Logs") {
                                store.removeAll()
                            }
                        }
                    }
                }
            }.listStyle(.sidebar).scrollContentBackground(.hidden)
        }
    }

    // MARK: - Preview

    #if DEBUG
        @available(macOS 13, *)
        struct UserSettingsView_Previews: PreviewProvider {
            static var previews: some View {
                SettingsView()
            }
        }
    #endif
#endif
