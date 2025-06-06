// The MIT License (MIT)
//
// 

#if !os(watchOS)

    import SwiftUI

    struct TimingView: View {
        let viewModel: TimingViewModel

        var body: some View {
            #if os(tvOS)
                ForEach(viewModel.sections) { item in
                    Section {
                        Button(action: {}) {
                            TimingSectionView(viewModel: item, parent: viewModel)
                        }
                    }
                }
            #else
                VStack(spacing: 16) {
                    ForEach(viewModel.sections) {
                        TimingSectionView(viewModel: $0, parent: viewModel)
                    }
                }
            #endif
        }
    }

    private struct TimingSectionView: View {
        let viewModel: TimingRowSectionViewModel
        let parent: TimingViewModel

        var body: some View {
            VStack(spacing: 6) {
                HStack {
                    Text(viewModel.title)
                    #if os(macOS)
                        .font(.headline)
                    #else
                        .font(.subheadline)
                    #endif
                        .lineLimit(1)
                        .foregroundColor(viewModel.isHeader ? .secondary : .primary)
                    Spacer()
                }.padding(.top, viewModel.isHeader ? 16 : 0)
                if viewModel.isHeader {
                    Divider()
                }
                if !viewModel.items.isEmpty {
                    ForEach(viewModel.items) { item in
                        TimingRowView(viewModel: item, parent: parent)
                    }
                }
            }
        }
    }

    private struct TimingRowView: View {
        let viewModel: TimingRowViewModel
        let parent: TimingViewModel

        #if os(tvOS)
            let barHeight: CGFloat = 20
            let spacing: CGFloat = 48
        #else
            let barHeight: CGFloat = 14
            let spacing: CGFloat = 12
        #endif

        @Environment(\.sizeCategory) var sizeCategory

        var body: some View {
            HStack(alignment: .center, spacing: spacing) {
                ZStack(alignment: .leading) {
                    makeTitle(viewModel.title)
                    makeTitle(parent.longestTitle).invisible() // Calculates width
                }.layoutPriority(1)

                bar

                #if !os(watchOS)
                    ZStack(alignment: .trailing) {
                        makeValue(viewModel.value)
                        makeValue(parent.longestValue).invisible() // Calculates width
                    }.layoutPriority(1)
                #endif
            }
        }

        private var bar: some View {
            GeometryReader { proxy in
                let start = max(0, min(1, viewModel.start))
                let length = min(1 - start, viewModel.length)
                RoundedRectangle(cornerRadius: 2 * sizeCategory.scale)
                    .fill(Color(viewModel.color))
                    .frame(width: max(2, proxy.size.width * length))
                    .padding(.leading, proxy.size.width * start)
            }
            .frame(height: barHeight * sizeCategory.scale)
        }

        private func makeTitle(_ text: String) -> some View {
            Text(text)
            #if os(macOS)
                .font(.subheadline)
            #else
                .font(.footnote)
            #endif
                .lineLimit(1)
                .foregroundColor(.secondary)
        }

        private func makeValue(_ text: String) -> some View {
            Text(text)
            #if os(macOS)
                .font(.system(.subheadline, design: .monospaced))
            #else
                .font(.system(.caption, design: .monospaced))
            #endif
                .lineLimit(1)
                .foregroundColor(.secondary)
        }
    }

    final class TimingViewModel {
        let sections: [TimingRowSectionViewModel]

        init(sections: [TimingRowSectionViewModel]) {
            self.sections = sections
        }

        private(set) lazy var longestTitle: String = allRows.map(\.title).max { $0.count < $1.count } ?? ""

        private(set) lazy var longestValue: String = allRows.map(\.value).max { $0.count < $1.count } ?? ""

        private var allRows: [TimingRowViewModel] {
            sections.flatMap(\.items)
        }
    }

    final class TimingRowSectionViewModel: Identifiable {
        let title: String
        let items: [TimingRowViewModel]
        var isHeader = false

        var id: ObjectIdentifier { ObjectIdentifier(self) }

        init(title: String, items: [TimingRowViewModel], isHeader: Bool = false) {
            self.title = title
            self.items = items
            self.isHeader = isHeader
        }
    }

    final class TimingRowViewModel: Identifiable {
        let title: String
        let value: String
        let color: UXColor
        // [0, 1]
        let start: CGFloat
        // [0, 1]
        let length: CGFloat

        var id: ObjectIdentifier { ObjectIdentifier(self) }

        init(title: String, value: String, color: UXColor, start: CGFloat, length: CGFloat) {
            self.title = title
            self.value = value
            self.color = color
            self.start = start
            self.length = length
        }
    }

    #if DEBUG
        struct TimingView_Previews: PreviewProvider {
            static var previews: some View {
                ScrollView {
                    TimingView(viewModel: .init(sections: mockSections))
                }
                .padding()
                #if !os(tvOS)
                    .previewLayout(.sizeThatFits)
                #endif
            }
        }

        private let mockSections = [
            TimingRowSectionViewModel(title: "Response", items: [
                TimingRowViewModel(title: "Scheduling", value: "0.01ms", color: .systemBlue, start: 0.0, length: 0.001),
                TimingRowViewModel(title: "Waiting", value: "41.2ms", color: .systemBlue, start: 0.0, length: 0.4),
                TimingRowViewModel(title: "Download", value: "0.2ms", color: .systemRed, start: 0.4, length: 0.05),
            ]),
            TimingRowSectionViewModel(title: "Cache Lookup", items: [
                TimingRowViewModel(title: "Waiting", value: "50.2ms", color: .systemYellow, start: 0.45, length: 0.3),
                TimingRowViewModel(title: "Download", value: "30.0ms", color: .systemGreen, start: 0.75, length: 100.0),
            ]),
        ]
    #endif

#endif
