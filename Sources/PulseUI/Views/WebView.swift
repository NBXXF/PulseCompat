// The MIT License (MIT)
//
// 

import SwiftUI

#if os(iOS) || os(visionOS)

    import UIKit
    import WebKit

    struct WebView: UIViewRepresentable {
        let data: Data
        let contentType: String

        func makeUIView(context _: Context) -> WKWebView {
            let webView = WKWebView(frame: .zero, configuration: .init())
            webView.load(data, mimeType: contentType, characterEncodingName: "UTF8", baseURL: FileManager.default.temporaryDirectory)
            return webView
        }

        func updateUIView(_: WKWebView, context _: Context) {
            // Do nothing
        }
    }
#endif

#if os(macOS)

    import AppKit
    import WebKit

    struct WebView: NSViewRepresentable {
        let data: Data
        let contentType: String

        func makeNSView(context _: Context) -> WKWebView {
            let webView = WKWebView(frame: .zero, configuration: .init())
            webView.load(data, mimeType: contentType, characterEncodingName: "UTF8", baseURL: FileManager.default.temporaryDirectory)
            return webView
        }

        func updateNSView(_: WKWebView, context _: Context) {
            // Do nothing
        }
    }

#endif
