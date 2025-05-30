// The MIT License (MIT)
//
// 

import Foundation

extension NSMutableAttributedString {
    func append(_ string: String, _ attributes: [NSAttributedString.Key: Any] = [:]) {
        append(NSAttributedString(string: string, attributes: attributes))
    }

    func addAttributes(_ attributes: [NSAttributedString.Key: Any]) {
        addAttributes(attributes, range: NSRange(location: 0, length: string.count))
    }
}
