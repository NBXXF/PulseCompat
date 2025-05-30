// The MIT License (MIT)
//
// 

import Combine
import CoreData
import Foundation
import Pulse
import SwiftUI

#if os(iOS) || os(macOS) || os(visionOS)

    @available(iOS 15, macOS 13, visionOS 1.0, *)
    struct SessionPickerView: View {
        @Binding var selection: Set<UUID>

        var body: some View {
            SessionListView(selection: $selection, sharedSessions: .constant(nil))
            #if os(iOS) || os(visionOS)
                .environment(\.editMode, .constant(.active))
                .inlineNavigationTitle("Sessions")
            #endif
        }
    }

#endif
