// The MIT License (MIT)
//
// 

#if !os(watchOS)

    import Pulse
    import SwiftUI

    struct NetworkCURLCell: View {
        let task: NetworkTaskEntity

        var body: some View {
            NavigationLink(destination: destination) {
                NetworkMenuCell(
                    icon: "terminal.fill",
                    tintColor: .secondary,
                    title: "cURL Representation",
                    details: ""
                )
            }
        }

        private var destination: some View {
            let curl = task.cURLDescription()
            let string = TextRenderer().render(curl, role: .body2, style: .monospaced)
            let viewModel = RichTextViewModel(string: string)
            viewModel.isLinkDetectionEnabled = false
            return RichTextView(viewModel: viewModel)
                .navigationTitle("cURL Representation")
        }
    }

#endif
