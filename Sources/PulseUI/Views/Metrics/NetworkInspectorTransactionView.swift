// The MIT License (MIT)
//
// 

#if !os(watchOS)

    import CoreData
    import Pulse
    import SwiftUI

    @available(iOS 15, visionOS 1.0, *)
    struct NetworkInspectorTransactionView: View {
        @ObservedObject var viewModel: NetworkInspectorTransactionViewModel

        var body: some View {
            Section {
                contents
            }
        }

        @ViewBuilder
        private var contents: some View {
            NetworkRequestStatusCell(viewModel: viewModel.statusViewModel)
            #if os(macOS)
                .padding(.bottom, 8)
            #endif
            viewModel.timingViewModel.map(TimingView.init)
            NavigationLink(destination: destintionTransactionDetails) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                    if let size = viewModel.transferSizeViewModel {
                        transferSizeView(size: size)
                    }
                }
            }
            NetworkRequestInfoCell(viewModel: viewModel.requestViewModel)
        }

        @available(iOS 15, visionOS 1.0, *)
        private func transferSizeView(size: NetworkInspectorTransferInfoViewModel) -> some View {
            let font = TextHelper().font(style: .init(role: .subheadline, style: .monospacedDigital, width: .condensed))
            return (Text(Image(systemName: "arrow.down.circle")) +
                Text(" ") +
                Text(size.totalBytesSent) +
                Text("  ") +
                Text(Image(systemName: "arrow.up.circle")) +
                Text(" ") +
                Text(size.totalBytesReceived))
                .lineLimit(1)
                .font(Font(font))
                .foregroundColor(.secondary)
        }

        private var destintionTransactionDetails: some View {
            NetworkDetailsView(title: "Transaction Details") { viewModel.details() }
        }
    }

    // MARK: - ViewModel

    final class NetworkInspectorTransactionViewModel: ObservableObject, Identifiable {
        let id: NSManagedObjectID
        let title: String
        let transaction: NetworkTransactionMetricsEntity
        let statusViewModel: NetworkRequestStatusCellModel
        let timingViewModel: TimingViewModel?
        let requestViewModel: NetworkRequestInfoCellViewModel
        let transferSizeViewModel: NetworkInspectorTransferInfoViewModel?
        let details: () -> NSAttributedString

        init(transaction: NetworkTransactionMetricsEntity, task: NetworkTaskEntity) {
            id = transaction.objectID
            title = transaction.fetchType.title
            self.transaction = transaction
            statusViewModel = NetworkRequestStatusCellModel(transaction: transaction)
            requestViewModel = NetworkRequestInfoCellViewModel(transaction: transaction)
            timingViewModel = TimingViewModel(transaction: transaction, task: task)

            if transaction.fetchType == .networkLoad {
                transferSizeViewModel = NetworkInspectorTransferInfoViewModel(transferSize: transaction.transferSize)
            } else {
                transferSizeViewModel = nil
            }

            details = {
                let renderer = TextRenderer(options: .sharing)
                let sections = KeyValueSectionViewModel.makeDetails(for: transaction)
                renderer.render(sections)
                return renderer.make()
            }
        }
    }

    #if DEBUG
        @available(iOS 15, visionOS 1.0, *)
        struct NetworkInspectorTransactionView_Previews: PreviewProvider {
            static var previews: some View {
                NavigationView {
                    List {
                        ForEach(mockTask.orderedTransactions, id: \.index) {
                            NetworkInspectorTransactionView(viewModel: .init(transaction: $0, task: mockTask))
                        }
                    }.frame(width: 600)
                }
                #if os(macOS)
                .frame(width: 1000, height: 1000)
                #endif
                #if os(watchOS)
                .navigationViewStyle(.stack)
                #endif
            }
        }

        private let mockTask = LoggerStore.preview.entity(for: .createAPI)

    #endif

#endif
