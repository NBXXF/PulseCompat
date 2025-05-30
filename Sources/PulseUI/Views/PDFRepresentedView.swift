// The MIT License (MIT)
//
// 

import SwiftUI

#if os(iOS) || os(visionOS)
    import PDFKit

    struct PDFKitRepresentedView: UIViewRepresentable {
        let document: PDFDocument

        func makeUIView(context _: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.document = document
            return pdfView
        }

        func updateUIView(_: PDFView, context _: Context) {
            // Do nothing
        }
    }

#elseif os(macOS)
    import PDFKit

    struct PDFKitRepresentedView: NSViewRepresentable {
        let document: PDFDocument

        func makeNSView(context _: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.document = document
            pdfView.autoScales = true
            return pdfView
        }

        func updateNSView(_: PDFView, context _: Context) {
            // Do nothing
        }
    }
#endif
