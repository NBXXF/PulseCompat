// The MIT License (MIT)
//
// 

import Combine
import CoreData
import Pulse
import SwiftUI

#if os(iOS) || os(macOS) || os(visionOS)
    import PDFKit
#endif

final class FileViewerViewModel: ObservableObject {
    let title: String
    private let context: FileViewerViewModelContext
    var contentType: NetworkLogger.ContentType? { context.contentType }
    private let getData: () -> Data

    private(set) lazy var contents: Contents = render(data: getData())

    init(title: String, context: FileViewerViewModelContext, data: @escaping () -> Data) {
        self.title = title
        self.context = context
        getData = data
    }

    enum Contents {
        case image(ImagePreviewViewModel)
        case other(RichTextViewModel)
        #if os(iOS) || os(macOS) || os(visionOS)
            case pdf(PDFDocument)
        #endif
    }

    private func render(data: Data) -> Contents {
        if contentType?.isImage ?? false, let image = UXImage(data: data) {
            return .image(ImagePreviewViewModel(image: image, data: data, context: context))
        } else if contentType?.isPDF ?? false, let pdf = makePDF(data: data) {
            return pdf
        } else {
            let string = TextRenderer().render(data, contentType: contentType, error: context.error)
            return .other(RichTextViewModel(string: string, contentType: contentType))
        }
    }

    private func makePDF(data: Data) -> Contents? {
        #if os(iOS) || os(macOS) || os(visionOS)
            if let pdf = PDFDocument(data: data) {
                return .pdf(pdf)
            }
        #endif
        return nil
    }
}
