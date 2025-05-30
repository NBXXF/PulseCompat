// The MIT License (MIT)
//
// 

#if os(macOS)

    import SwiftUI

    struct RichTextViewSearchToobar: View {
        @ObservedObject var viewModel: RichTextViewModel

        var isSearchOptionsHidden = false

        var body: some View {
            HStack {
                if !viewModel.matches.isEmpty {
                    HStack(spacing: 8) {
                        Button(action: viewModel.previousMatch) {
                            Image(systemName: "chevron.left.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.matches.isEmpty)

                        Text(viewModel.matches.isEmpty ? "0 / 0" : "\(viewModel.selectedMatchIndex + 1) / \(viewModel.matches.count)")
                            .font(Font.body.monospacedDigit())
                            .foregroundColor(.secondary)

                        Button(action: viewModel.nextMatch) {
                            Image(systemName: "chevron.right.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.matches.isEmpty)
                    }
                    .padding(.leading, 3)
                }

                Spacer()

                SearchBar(title: "Search", text: $viewModel.searchTerm).frame(maxWidth: 130)

                StringSearchOptionsMenu(options: $viewModel.searchOptions, isKindNeeded: false)
                    .fixedSize()
            }
            .padding(6)
        }
    }

#endif
