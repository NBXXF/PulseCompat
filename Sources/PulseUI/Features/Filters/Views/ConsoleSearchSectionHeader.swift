// The MIT License (MIT)
//
// 

import SwiftUI

struct ConsoleSectionHeader: View {
    let icon: String
    let title: String
    let reset: () -> Void
    let isDefault: Bool

    init<Filter: ConsoleFilterProtocol>(
        icon: String,
        title: String,
        filter: Binding<Filter>,
        default: Filter? = nil
    ) {
        self.icon = icon
        self.title = title
        reset = { filter.wrappedValue = `default` ?? Filter() }
        isDefault = filter.wrappedValue == `default` ?? Filter()
    }

    #if os(macOS)
        var body: some View {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                    Text(title)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !isDefault {
                    Button(action: reset) {
                        Image(systemName: "arrow.uturn.left")
                    }
                    .foregroundColor(.secondary)
                    .disabled(isDefault)
                }
            }.buttonStyle(.plain)
        }

    #elseif os(iOS) || os(visionOS)
        var body: some View {
            HStack {
                Text(title)
                if !isDefault {
                    Button(action: reset) {
                        Image(systemName: "arrow.uturn.left")
                    }
                    .padding(.bottom, 3)
                } else {
                    Button(action: {}) {
                        Image(systemName: "arrow.uturn.left")
                    }
                    .padding(.bottom, 3)
                    .hidden()
                    .accessibilityHidden(true)
                }
            }
        }
    #else
        var body: some View {
            Text(title)
        }
    #endif
}
