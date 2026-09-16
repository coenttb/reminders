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

nonisolated let localizedCaseInsensitive = LocalizedCaseInsensitiveCollation()

nonisolated struct LocalizedCaseInsensitiveCollation: StructuredQueriesSQLiteCore.DatabaseCollation {
    var name: String { "localizedCaseInsensitive" }

    func compare(_ lhs: UnsafeRawBufferPointer, _ rhs: UnsafeRawBufferPointer) -> CollationOrder {
        let (lhs, rhs) = unsafe (String(decoding: lhs, as: UTF8.self), String(decoding: rhs, as: UTF8.self))
        return CollationOrder(lhs.localizedCaseInsensitiveCompare(rhs))
    }
}
