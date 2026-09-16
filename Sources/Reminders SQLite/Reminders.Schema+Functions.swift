import Foundation
import Reminders
import SQLiteData

extension Reminders.Schema {
    @DatabaseFunction(isDeterministic: true)
    nonisolated static func localizedCaseInsensitiveContains(_ text: String, _ query: String) -> Bool {
        text.localizedCaseInsensitiveContains(query)
    }

    @DatabaseFunction(isDeterministic: true)
    nonisolated static func searchFolded(_ text: String) -> String {
        text.lowercased()
    }

    @DatabaseFunction(isDeterministic: true)
    nonisolated static func hasCaseInsensitivePrefix(_ text: String, _ prefix: String) -> Bool {
        text.lowercased().hasPrefix(prefix.lowercased())
    }

    @DatabaseCollation
    nonisolated static func localizedCaseInsensitive(_ lhs: String, _ rhs: String) -> CollationOrder {
        CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
    }
}
