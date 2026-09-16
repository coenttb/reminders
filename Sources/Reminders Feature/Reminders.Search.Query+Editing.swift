import Foundation
public import Models
public import Reminder
public import Reminders
import FoundationEssentials_Extensions
import Standard_Library_Extensions

extension Reminders.Search.Query {
    public static func committingText(_ search: Self) -> Self {
        guard search.tagPrefix == nil, !search.text.trimmed.isEmpty else { return search }
        var committed = search
        committed.tokens.append(.near(search.text.trimmed))
        committed.text = ""
        return committed
    }

    public mutating func commitText() { self = Self.committingText(self) }

    public static func adding(_ search: Self, tag: Tag<Reminder>) -> Self {
        var added = search
        added.tokens.append(.tag(tag))
        added.text = ""
        return added
    }

    public mutating func add(tag: Tag<Reminder>) { self = Self.adding(self, tag: tag) }
}
