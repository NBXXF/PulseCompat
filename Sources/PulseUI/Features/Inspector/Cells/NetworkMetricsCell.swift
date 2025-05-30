// The MIT License (MIT)
//
// 

#if !os(watchOS)

    import Pulse
    import SwiftUI

    @available(iOS 15, visionOS 1, macOS 13, *)
    struct NetworkMetricsCell: View {
        let task: NetworkTaskEntity

        var body: some View {
            NavigationLink(destination: destinationMetrics) {
                NetworkMenuCell(
                    icon: "clock.fill",
                    tintColor: .orange,
                    title: "Metrics",
                    details: ""
                )
            }.disabled(!task.hasMetrics)
        }

        private var destinationMetrics: some View {
            NetworkInspectorMetricsViewModel(task: task).map {
                NetworkInspectorMetricsView(viewModel: $0)
            }
        }
    }

#endif
