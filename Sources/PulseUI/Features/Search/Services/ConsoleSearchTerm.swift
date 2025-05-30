// The MIT License (MIT)
//
// 

import Foundation

struct ConsoleSearchTerm: Identifiable, Hashable, Codable {
    var id: ConsoleSearchTerm { self }

    var text: String
    var options: StringSearchOptions
}
