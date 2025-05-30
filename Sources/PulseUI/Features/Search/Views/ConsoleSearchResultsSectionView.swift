// The MIT License (MIT)
//
// 

#if os(iOS) || os(macOS) || os(visionOS)

    import Combine
    import CoreData
    import Pulse
    import SwiftUI

    @available(iOS 15, visionOS 1.0, macOS 13, *)
    struct ConsoleSearchResultView: View {
        let viewModel: ConsoleSearchResultViewModel
        var limit: Int = 4
        var isSeparatorNeeded = false

        @EnvironmentObject private var environment: ConsoleEnvironment

        var body: some View {
            ConsoleEntityCell(entity: viewModel.entity)
            let occurrences = Array(viewModel.occurrences).filter { $0.scope.isDisplayedInResults }
            ForEach(occurrences.prefix(limit)) { item in
                NavigationLink(destination: ConsoleSearchResultView.makeDestination(for: item, entity: viewModel.entity).injecting(environment)) {
                    makeCell(for: item)
                }
            }
            if occurrences.count > limit {
                let total = occurrences.count > ConsoleSearchMatch.limit ? "\(ConsoleSearchMatch.limit)+" : "\(occurrences.count)"
                #if os(macOS)
                    Text("Total Results: \(total)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                        .padding(.bottom, 8)
                #else
                    NavigationLink(destination: ConsoleSearchResultDetailsView(viewModel: viewModel).injecting(environment)) {
                        Text("Total Results: ")
                            .font(ConsoleConstants.fontBody) +
                            Text(total)
                            .font(ConsoleConstants.fontBody)
                            .foregroundColor(.secondary)
                    }
                #endif
            }
            #if os(iOS) || os(visionOS)
                if isSeparatorNeeded {
                    PlainListGroupSeparator()
                }
            #endif
        }

        @ViewBuilder
        private func makeCell(for occurrence: ConsoleSearchOccurrence) -> some View {
            let contents = VStack(alignment: .leading, spacing: 4) {
                Text(occurrence.preview)
                    .lineLimit(3)
                Text(occurrence.scope.title + " (\(occurrence.line):\(occurrence.range.lowerBound + 1))")
                    .font(ConsoleConstants.fontInfo)
                    .foregroundColor(.secondary)
            }
            #if os(macOS)
            .listRowSeparator(.visible)
            .padding(.leading, 16)
            #endif
            if #unavailable(iOS 16) {
                contents.padding(.vertical, 4)
            } else {
                #if os(macOS)
                    contents.padding(.vertical, 4)
                #else
                    contents
                #endif
            }
        }

        @ViewBuilder
        static func makeDestination(for occurrence: ConsoleSearchOccurrence, entity: NSManagedObject) -> some View {
            _makeDestination(for: occurrence, entity: entity)
                .environment(\.textViewSearchContext, occurrence.searchContext)
        }

        @ViewBuilder
        private static func _makeDestination(for occurrence: ConsoleSearchOccurrence, entity: NSManagedObject) -> some View {
            switch LoggerEntity(entity) {
            case let .message(message):
                ConsoleMessageDetailsView(message: message)
            case let .task(task):
                _makeDestination(for: occurrence, task: task)
            }
        }

        @ViewBuilder
        private static func _makeDestination(for occurrence: ConsoleSearchOccurrence, task: NetworkTaskEntity) -> some View {
            switch occurrence.scope {
            case .originalRequestHeaders, .currentRequestHeaders, .responseHeaders:
                EmptyView() // Reserved
            case .requestBody:
                NetworkInspectorRequestBodyView(viewModel: .init(task: task))
            case .responseBody:
                NetworkInspectorResponseBodyView(viewModel: .init(task: task))
            case .url, .message, .metadata:
                EmptyView()
            }
        }
    }

    @available(iOS 15, visionOS 1.0, macOS 13, *)
    struct ConsoleSearchResultDetailsView: View {
        let viewModel: ConsoleSearchResultViewModel

        var body: some View {
            List {
                ConsoleSearchResultView(viewModel: viewModel, limit: Int.max)
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 0)
            .inlineNavigationTitle("Search Results")
        }
    }

    #if os(iOS) || os(visionOS)
        @available(iOS 15, visionOS 1.0, *)
        struct PlainListGroupSeparator: View {
            var body: some View {
                Rectangle().foregroundColor(.clear) // DIY separator
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.separator.opacity(0.2))
                    .listRowSeparator(.hidden)
                    .frame(height: 12)
            }
        }
    #endif

    @available(iOS 15, visionOS 1.0, *)
    struct PlainListSectionHeader<Content: View>: View {
        var title: String?
        @ViewBuilder let content: () -> Content

        var body: some View {
            contents
                .padding(.top, 8)
                .listRowBackground(Color.separator.opacity(0.2))
            #if os(iOS) || os(visionOS)
                .listRowSeparator(.hidden)
            #endif
        }

        @ViewBuilder
        private var contents: some View {
            if let title = title {
                HStack(alignment: .bottom, spacing: 0) {
                    Text(title)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
            } else {
                content()
            }
        }
    }

    @available(iOS 15, visionOS 1.0, *)
    extension PlainListSectionHeader where Content == Text {
        init(title: String) {
            self.init(title: title, content: { Text(title) })
        }
    }

    @available(iOS 15, visionOS 1.0, *)
    struct PlainListSeeAllView: View {
        let count: Int

        var body: some View {
            (Text("Show All").foregroundColor(.accentColor) +
                Text("  (\(count))"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @available(iOS 15, visionOS 1.0, *)
    struct PlainListSectionHeaderSeparator: View {
        let title: String

        var body: some View {
            HStack(alignment: .bottom, spacing: 0) {
                Text(title)
                    .foregroundColor(.secondary)
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
        }
    }

#endif
