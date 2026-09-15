import Foundation
import SQLiteData

/// Whether the text contains the query as Swift's `localizedCaseInsensitiveContains` sees it;
/// SQLite's `LIKE` folds only ASCII case.
@DatabaseFunction(isDeterministic: true)
nonisolated func localizedCaseInsensitiveContains(_ text: String, _ query: String) -> Bool {
    text.localizedCaseInsensitiveContains(query)
}

/// Whether the text starts with the prefix, ignoring case as Swift's `lowercased()` does.
@DatabaseFunction(isDeterministic: true)
nonisolated func hasCaseInsensitivePrefix(_ text: String, _ prefix: String) -> Bool {
    text.lowercased().hasPrefix(prefix.lowercased())
}

/// Titles order as Swift's `localizedCaseInsensitiveCompare` orders them.
@DatabaseCollation
nonisolated func localizedCaseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
    CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
}
