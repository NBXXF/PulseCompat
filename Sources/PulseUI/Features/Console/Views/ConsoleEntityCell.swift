// The MIT License (MIT)
//
// 

import CoreData
import Foundation
import Pulse
import SwiftUI

@available(iOS 15, macOS 13, visionOS 1.0, *)
struct ConsoleEntityCell: View {
    let entity: NSManagedObject

    var body: some View {
        switch LoggerEntity(entity) {
        case let .message(message):
            _ConsoleMessageCell(message: message)
        case let .task(task):
            _ConsoleTaskCell(task: task)
        }
    }
}

@available(iOS 15, macOS 13, visionOS 1.0, *)
private struct _ConsoleMessageCell: View {
    let message: LoggerMessageEntity

    @State private var shareItems: ShareItems?

    var body: some View {
        #if os(iOS) || os(visionOS)
            let cell = ConsoleMessageCell(message: message, isDisclosureNeeded: true)
                .background(NavigationLink("", destination: ConsoleMessageDetailsView(message: message)).opacity(0))
        #else
            let cell = NavigationLink(destination: ConsoleMessageDetailsView(message: message)) {
                ConsoleMessageCell(message: message)
            }
        #endif

        #if os(iOS) || os(macOS) || os(visionOS)
            cell.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(action: { shareItems = ShareService.share(message, as: .html) }) {
                    Label("Share", systemImage: "square.and.arrow.up.fill")
                }.tint(.blue)
            }
            .contextMenu {
                ContextMenu.MessageContextMenu(message: message, shareItems: $shareItems)
            }
            #if os(iOS) || os(visionOS)
            .sheet(item: $shareItems, content: ShareView.init)
            #else
            .popover(item: $shareItems, attachmentAnchor: .point(.leading), arrowEdge: .leading) { ShareView($0) }
            #endif
        #else
            cell
        #endif
    }
}

@available(iOS 15, macOS 13, visionOS 1.0, *)
private struct _ConsoleTaskCell: View {
    let task: NetworkTaskEntity
    @State private var shareItems: ShareItems?
    @State private var sharedTask: NetworkTaskEntity?
    @Environment(\.store) private var store
    @EnvironmentObject private var environment: ConsoleEnvironment

    var body: some View {
        #if os(iOS) || os(visionOS)
            let cell = ConsoleTaskCell(task: task, isDisclosureNeeded: true)
                .background(NavigationLink("", destination: inspector).opacity(0))
        #else
            let cell = NavigationLink(destination: inspector) {
                ConsoleTaskCell(task: task)
            }
        #endif

        #if os(iOS) || os(macOS) || os(visionOS)
            cell.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(action: {
                    #if os(iOS) || os(visionOS)
                        shareItems = ShareService.share(task, as: .html, store: store)
                    #else
                        sharedTask = task
                    #endif
                }) {
                    Label("Share", systemImage: "square.and.arrow.up.fill")
                }.tint(.blue)
            }
            .contextMenu {
                #if os(iOS) || os(visionOS)
                    ContextMenu.NetworkTaskContextMenuItems(task: task, sharedItems: $shareItems)
                #else
                    ContextMenu.NetworkTaskContextMenuItems(task: task, sharedTask: $sharedTask)
                #endif
            }
            #if os(iOS) || os(visionOS)
            .sheet(item: $shareItems, content: ShareView.init)
            #else
            .popover(item: $sharedTask, attachmentAnchor: .point(.leading), arrowEdge: .leading) { ShareNetworkTaskView(task: $0) }
            #endif
        #else
            cell
        #endif
    }

    private var inspector: some View {
        // We don't own NavigationView, so we have to inject the dependencies
        NetworkInspectorView(task: task)
            .injecting(environment)
    }
}
