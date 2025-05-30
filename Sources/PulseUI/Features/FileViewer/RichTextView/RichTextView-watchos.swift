// The MIT License (MIT)
//
// 

import Pulse
import SwiftUI

#if os(watchOS) || os(tvOS)

    struct RichTextView: View {
        let viewModel: RichTextViewModel

        var body: some View {
            ScrollView {
                if let string = viewModel.attributedString {
                    Text(string)
                } else {
                    Text(viewModel.text)
                }
            }
            #if os(watchOS)
            .toolbar {
                if #available(watchOS 9.0, *) {
                    ShareLink(item: viewModel.text)
                }
            }
            #endif
        }
    }

    final class RichTextViewModel: ObservableObject {
        let text: String
        let attributedString: AttributedString?

        var isLinkDetectionEnabled = true
        var isEmpty: Bool { text.isEmpty }

        init(string: String) {
            text = string
            attributedString = nil
        }

        init(string: NSAttributedString, contentType _: NetworkLogger.ContentType? = nil) {
            attributedString = try? AttributedString(string, including: \.uiKit)
            text = string.string
        }
    }

#endif
