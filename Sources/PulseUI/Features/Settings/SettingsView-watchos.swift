// The MIT License (MIT)
//
// 

#if os(watchOS)

    import Pulse
    import SwiftUI

    public struct SettingsView: View {
        private let store: LoggerStore

        @State private var isShowingShareView = false

        public init(store: LoggerStore = .shared) {
            self.store = store
        }

        public var body: some View {
            Form {
                Section {
                    if !UserSettings.shared.isRemoteLoggingHidden,
                       store === RemoteLogger.shared.store
                    {
                        #if targetEnvironment(simulator)
                            RemoteLoggerSettingsView(viewModel: .shared)
                        #else
                            RemoteLoggerSettingsView(viewModel: .shared)
                                .disabled(true)
                                .foregroundColor(.secondary)
                            Text("Not available on watchOS devices")
                                .foregroundColor(.secondary)
                        #endif
                    }
                }
                Section {
                    if #available(watchOS 9, *) {
                        Button("Share Store") { isShowingShareView = true }
                    }
                }
                Section {
                    NavigationLink(destination: StoreDetailsView(source: .store(store))) {
                        Text("Store Info")
                    }
                    if !(store.options.contains(.readonly)) {
                        Button(role: .destructive, action: { store.removeAll() }) {
                            Text("Remove Logs")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingShareView) {
                if #available(watchOS 9, *) {
                    NavigationView {
                        ShareStoreView {
                            isShowingShareView = false
                        }
                    }
                }
            }
        }
    }

    #if DEBUG
        struct SettingsView_Previews: PreviewProvider {
            static var previews: some View {
                NavigationView {
                    SettingsView(store: .mock)
                }.navigationViewStyle(.stack)
            }
        }
    #endif
#endif
