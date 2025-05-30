// The MIT License (MIT)
//
// 

import Pulse
import SwiftUI

struct ConsoleSearchToggleCell: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        #if os(macOS)
            HStack {
                Toggle(title, isOn: $isOn)
                Spacer()
            }
        #else
            Toggle(title, isOn: $isOn)
        #endif
    }
}
