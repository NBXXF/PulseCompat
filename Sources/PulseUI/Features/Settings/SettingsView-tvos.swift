// The MIT License (MIT)
//
// 

#if os(tvOS)

    import Pulse
    import SwiftUI

    public struct SettingsView: View {
        private let store: LoggerStore

        public init(store: LoggerStore = .shared) {
            self.store = store
        }

        public var body: some View {
            Form {
                if !UserSettings.shared.isRemoteLoggingHidden,
                   store === RemoteLogger.shared.store
                {
                    RemoteLoggerSettingsView(viewModel: .shared)
                }
                Section {
                    NavigationLink(destination: StoreDetailsView(source: .store(store))) {
                        Text("Store Info")
                    }
                    if !store.options.contains(.readonly) {
                        Button(role: .destructive, action: { store.removeAll() }) {
                            Text("Remove Logs")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .frame(maxWidth: 800)
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
