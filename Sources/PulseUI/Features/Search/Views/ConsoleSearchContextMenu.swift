// The MIT License (MIT)
//
// 

#if os(iOS) || os(visionOS) || os(macOS)

    import Combine
    import CoreData
    import Pulse
    import SwiftUI

    @available(iOS 15, visionOS 1.0, *)
    struct ConsoleSearchContextMenu: View {
        @EnvironmentObject private var viewModel: ConsoleSearchViewModel

        var body: some View {
            Menu {
                StringSearchOptionsMenu(options: $viewModel.options)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            }
        }
    }
#endif
