// The MIT License (MIT)
//
// 

import Foundation

final class Regex {
    private let regex: NSRegularExpression

    struct Options: OptionSet {
        let rawValue: Int

        static let caseInsensitive = Options(rawValue: 1 << 0)
        static let multiline = Options(rawValue: 1 << 1)
        static let dotMatchesLineSeparators = Options(rawValue: 1 << 2)
    }

    init(_ pattern: String, _ options: Options = []) throws {
        var ops = NSRegularExpression.Options()
        if options.contains(.caseInsensitive) { ops.insert(.caseInsensitive) }
        if options.contains(.multiline) { ops.insert(.anchorsMatchLines) }
        if options.contains(.dotMatchesLineSeparators) { ops.insert(.dotMatchesLineSeparators) }

        regex = try NSRegularExpression(pattern: pattern, options: ops)
    }

    func isMatch(_ s: String) -> Bool {
        let range = NSRange(s.startIndex ..< s.endIndex, in: s)
        return regex.firstMatch(in: s, options: [], range: range) != nil
    }

    func matches(in s: String) -> [Match] {
        let range = NSRange(s.startIndex ..< s.endIndex, in: s)
        return matches(in: s, range: range)
    }

    func matches(in s: String, range: NSRange) -> [Match] {
        let matches = regex.matches(in: s, options: [], range: range)
        return matches.map { match in
            let ranges = (0 ..< match.numberOfRanges)
                .map { match.range(at: $0) }
                .filter { $0.location != NSNotFound }
            return Match(fullMatch: s[Range(match.range, in: s)!],
                         groups: ranges.dropFirst().map { s[Range($0, in: s)!] })
        }
    }
}

extension Regex {
    struct Match {
        let fullMatch: Substring
        let groups: [Substring]
    }
}
