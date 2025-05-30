// The MIT License (MIT)
//
// 

#if os(iOS) || os(visionOS) || os(macOS)

    import Combine
    import CoreData
    import Pulse
    import SwiftUI

    @available(iOS 15, visionOS 1.0, *)
    struct ConsoleContextMenu: View {
        @EnvironmentObject private var environment: ConsoleEnvironment
        @Environment(\.router) private var router

        var body: some View {
            Menu {
                Section {
                    Button(action: { router.isShowingSessions = true }) {
                        Label("Sessions", systemImage: "list.bullet.clipboard")
                    }
                }
                #if os(iOS) || os(visionOS)
                    Section {
                        ConsoleSortByMenu()
                    }
                #endif
                Section {
                    Button(action: { router.isShowingSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    if !environment.store.options.contains(.readonly) {
                        Button(role: .destructive, action: environment.removeAllLogs) {
                            Label("Remove Logs", systemImage: "trash")
                        }
                    }
                }
                Section {
                    if !UserDefaults.standard.bool(forKey: "pulse-disable-support-prompts") {
                        Button(action: buttonGetPulseProTapped) {
                            Label("Get Pulse Pro", systemImage: "link")
                        }
                    }
                    Button(action: buttonSendFeedbackTapped) {
                        Label("Report Issue", systemImage: "envelope")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }

        private func buttonGetPulseProTapped() {
            URL(string: "https://pulselogger.com").map(openURL)
        }

        private func buttonSendFeedbackTapped() {
            URL(string: "https://github.com/kean/Pulse/issues").map(openURL)
        }

        private func openURL(_ url: URL) {
            #if os(macOS)
                NSWorkspace.shared.open(url)
            #else
                UIApplication.shared.open(url)
            #endif
        }
    }

    private struct ConsoleSortByMenu: View {
        @EnvironmentObject private var environment: ConsoleEnvironment

        var body: some View {
            Menu(content: {
                if environment.mode == .network {
                    Picker("Sort By", selection: $environment.listOptions.taskSortBy) {
                        ForEach(ConsoleListOptions.TaskSortBy.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                } else {
                    Picker("Sort By", selection: $environment.listOptions.messageSortBy) {
                        ForEach(ConsoleListOptions.MessageSortBy.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                }
                Picker("Ordering", selection: $environment.listOptions.order) {
                    Text("Descending").tag(ConsoleListOptions.Ordering.descending)
                    Text("Ascending").tag(ConsoleListOptions.Ordering.ascending)
                }
            }, label: {
                Label("Sort By", systemImage: "arrow.up.arrow.down")
            })
        }
    }
#endif
