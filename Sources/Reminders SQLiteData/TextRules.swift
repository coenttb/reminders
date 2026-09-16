import Foundation
import SQLiteData

@DatabaseFunction(isDeterministic: true)
nonisolated func localizedCaseInsensitiveContains(_ text: String, _ query: String) -> Bool {
    text.localizedCaseInsensitiveContains(query)
}

@DatabaseFunction(isDeterministic: true)
nonisolated func searchFolded(_ text: String) -> String {
    text.lowercased()
}

@DatabaseFunction(isDeterministic: true)
nonisolated func hasCaseInsensitivePrefix(_ text: String, _ prefix: String) -> Bool {
    text.lowercased().hasPrefix(prefix.lowercased())
}

@DatabaseCollation
nonisolated func localizedCaseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
    CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
}
