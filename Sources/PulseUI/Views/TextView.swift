// The MIT License (MIT)
//
// 

import SwiftUI

#if os(iOS) || os(tvOS) || os(visionOS)
    /// A simple text view for rendering attributed strings.
    struct TextView: UIViewRepresentable {
        let string: NSAttributedString

        func makeUIView(context _: Context) -> UXTextView {
            let textView = UITextView()
            configureTextView(textView)
            textView.attributedText = string
            return textView
        }

        func updateUIView(_: UXTextView, context _: Context) {
            // Do nothing
        }
    }

#elseif os(macOS)
    struct TextView: NSViewRepresentable {
        let string: NSAttributedString

        func makeNSView(context _: Context) -> NSScrollView {
            let scrollView = NSTextView.scrollableTextView()
            scrollView.hasVerticalScroller = false
            let textView = scrollView.documentView as! NSTextView
            configureTextView(textView)
            textView.attributedText = string
            return scrollView
        }

        func updateNSView(_: NSScrollView, context _: Context) {
            // Do nothing
        }
    }

#elseif os(watchOS)
    struct TextView: View {
        let string: NSAttributedString

        var body: some View {
            if let string = try? AttributedString(string, including: \.uiKit) {
                Text(string)
            } else {
                Text(string.string)
            }
        }
    }
#endif

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    private func configureTextView(_ textView: UXTextView) {
        textView.isSelectable = true
        textView.backgroundColor = .clear

        #if os(iOS) || os(macOS) || os(visionOS)
            textView.isEditable = false
            textView.isAutomaticLinkDetectionEnabled = false
        #endif

        #if os(iOS) || os(visionOS)
            textView.isScrollEnabled = false
            textView.adjustsFontForContentSizeCategory = true
            textView.textContainerInset = .zero
        #endif

        #if os(macOS)
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.textContainerInset = .zero
        #endif
    }
#endif
