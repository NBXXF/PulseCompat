// The MIT License (MIT)
//
// 

import Pulse
import SwiftUI

@available(iOS 15, visionOS 1.0, *)
struct NetworkRequestStatusSectionView: View {
    let viewModel: NetworkRequestStatusSectionViewModel

    var body: some View {
        NetworkRequestStatusCell(viewModel: viewModel.status)
        if let description = viewModel.errorDescription {
            NavigationLink(destination: destinaitionError) {
                Text(description)
                    .lineLimit(4)
                    .font(.callout)
            }
        }
        NetworkRequestInfoCell(viewModel: viewModel.requestViewModel)
    }

    @ViewBuilder
    private var destinaitionError: some View {
        NetworkDetailsView(title: "Error") { viewModel.errorDetailsViewModel }
    }
}

final class NetworkRequestStatusSectionViewModel {
    let status: NetworkRequestStatusCellModel
    let errorDescription: String?
    let requestViewModel: NetworkRequestInfoCellViewModel
    let errorDetailsViewModel: KeyValueSectionViewModel?

    init(task: NetworkTaskEntity, store: LoggerStore) {
        status = NetworkRequestStatusCellModel(task: task, store: store)
        errorDescription = task.state == .failure ? task.errorDebugDescription : nil
        requestViewModel = NetworkRequestInfoCellViewModel(task: task, store: store)
        errorDetailsViewModel = KeyValueSectionViewModel.makeErrorDetails(for: task)
    }
}

#if DEBUG
    @available(iOS 15, visionOS 1.0, *)
    struct NetworkRequestStatusSectionView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                List {
                    ForEach(MockTask.allEntities, id: \.objectID) { task in
                        Section {
                            NetworkRequestStatusSectionView(viewModel: .init(task: task, store: .mock))
                        }
                    }
                }
                #if os(macOS)
                .frame(width: 260)
                #endif
            }
        }
    }
#endif
