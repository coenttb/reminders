import Foundation
import SQLiteData

/// Whether the text contains the query as Swift's `localizedCaseInsensitiveContains` sees it;
/// SQLite's `LIKE` folds only ASCII case.
@DatabaseFunction(isDeterministic: true)
nonisolated func localizedCaseInsensitiveContains(_ text: String, _ query: String) -> Bool {
    text.localizedCaseInsensitiveContains(query)
}

/// The text as the search stores and compares it: lowercased as Swift's `lowercased()` does.
/// A reminder's title and notes are kept folded in a column, so a search compares them with
/// SQLite's own `instr` rather than calling a Swift function for every row.
@DatabaseFunction(isDeterministic: true)
nonisolated func searchFolded(_ text: String) -> String {
    text.lowercased()
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
