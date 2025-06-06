// The MIT License (MIT)
//
// 

import Pulse
import SwiftUI

// MARK: - View

struct NetworkInspectorTransferInfoView: View {
    let viewModel: NetworkInspectorTransferInfoViewModel

    var isSentHidden = false
    var isReceivedHidden = false

    #if os(watchOS)
        var body: some View {
            HStack(alignment: .center) {
                if !isSentHidden {
                    bytesSent
                }
                if !isReceivedHidden {
                    bytesReceived
                }
            }
            .frame(maxWidth: .infinity)
        }
    #else
        var body: some View {
            HStack {
                Spacer()
                bytesSent
                Spacer()

                Divider()

                Spacer()
                bytesReceived
                Spacer()
            }
        }
    #endif

    private var bytesSent: some View {
        makeView(
            title: "Sent",
            imageName: "arrow.up.circle",
            total: viewModel.totalBytesSent,
            headers: viewModel.headersBytesSent,
            body: viewModel.bodyBytesSent
        )
    }

    private var bytesReceived: some View {
        makeView(
            title: "Received",
            imageName: "arrow.down.circle",
            total: viewModel.totalBytesReceived,
            headers: viewModel.headersBytesReceived,
            body: viewModel.bodyBytesReceived
        )
    }

    private func makeView(title: String, imageName: String, total: String, headers: String, body: String) -> some View {
        VStack {
            HStack(alignment: .center, spacing: spacing) {
                Image(systemName: imageName)
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                    Text(total)
                }
                #if os(macOS)
                .font(.title3.weight(.medium))
                #else
                .font(.headline)
                #endif
            }
            .fixedSize()
            .padding(2)
            HStack(alignment: .center, spacing: 4) {
                VStack(alignment: .trailing) {
                    Text("Headers:")
                        .foregroundColor(.secondary)
                        .font(valueFont)
                    Text("Body:")
                        .foregroundColor(.secondary)
                        .font(valueFont)
                }
                VStack(alignment: .leading) {
                    Text(headers)
                        .font(valueFont)
                    Text(body)
                        .font(valueFont)
                }
            }
            .fixedSize()
        }
    }
}

#if os(macOS)
    private let valueFont: Font = .callout
#else
    private let valueFont: Font = .footnote
#endif

#if os(tvOS)
    private let spacing: CGFloat = 20
#else
    private let spacing: CGFloat? = nil
#endif

// MARK: - Preview

#if DEBUG
    struct NetworkInspectorTransferInfoView_Previews: PreviewProvider {
        static var previews: some View {
            NetworkInspectorTransferInfoView(viewModel: mockModel)
                .padding()
                .fixedSize()
                .previewLayout(.sizeThatFits)
        }
    }

    private let mockModel = NetworkInspectorTransferInfoViewModel(
        task: LoggerStore.preview.entity(for: .login)
    )

#endif

// MARK: - ViewModel

struct NetworkInspectorTransferInfoViewModel {
    let totalBytesSent: String
    let bodyBytesSent: String
    let headersBytesSent: String

    let totalBytesReceived: String
    let bodyBytesReceived: String
    let headersBytesReceived: String

    init(empty _: Bool) {
        totalBytesSent = "–"
        bodyBytesSent = "–"
        headersBytesSent = "–"
        totalBytesReceived = "–"
        bodyBytesReceived = "–"
        headersBytesReceived = "–"
    }

    init(task: NetworkTaskEntity) {
        self.init(transferSize: task.totalTransferSize)
    }

    init(transferSize: NetworkLogger.TransferSizeInfo) {
        totalBytesSent = formatBytes(transferSize.totalBytesSent)
        bodyBytesSent = formatBytes(transferSize.requestBodyBytesSent)
        headersBytesSent = formatBytes(transferSize.requestHeaderBytesSent)

        totalBytesReceived = formatBytes(transferSize.totalBytesReceived)
        bodyBytesReceived = formatBytes(transferSize.responseBodyBytesReceived)
        headersBytesReceived = formatBytes(transferSize.responseHeaderBytesReceived)
    }
}

private func formatBytes(_ count: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: max(0, count))
}
