// The MIT License (MIT)
//
// 

import CoreData
import Pulse
import SwiftUI

enum Components {
    #if os(iOS) || os(macOS) || os(visionOS)
        @available(iOS 15, macOS 13, visionOS 1, *)
        static func makeSessionPicker(selection: Binding<Set<UUID>>) -> some View {
            SessionPickerView(selection: selection)
        }
    #endif

    static func makeRichTextView(string: NSAttributedString) -> some View {
        RichTextView(viewModel: .init(string: string))
    }

    @available(iOS 15, macOS 13, visionOS 1, *)
    static func makeConsoleEntityCell(entity: NSManagedObject) -> some View {
        ConsoleEntityCell(entity: entity)
    }

    static func makePinView(for _: NetworkTaskEntity) -> some View {
        EmptyView()
    }

    static func makePinView(for _: LoggerMessageEntity) -> some View {
        EmptyView()
    }
}
