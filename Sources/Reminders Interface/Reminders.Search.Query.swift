import Foundation
import FoundationEssentials_Extensions
public import Organizing
public import Reminder
public import Reminders
import Standard_Library_Extensions
public import Tagged

extension Reminders.Search {
    public struct Query: Hashable, Sendable {
        public var text: String
        public var tokens: [Token]
        public var showCompleted: Bool

        public init(text: String = "", tokens: [Token] = [], showCompleted: Bool = false) {
            self.text = text
            self.tokens = tokens
            self.showCompleted = showCompleted
        }
    }
}

extension Reminders.Search.Query {
    public var isActive: Bool { !text.isEmpty || !tokens.isEmpty }

    public var tagPrefix: String? {
        text.removing(prefix: "#").map(String.init)
    }

    public var matchesReminders: Bool { isActive && (tagPrefix == nil || !tokens.isEmpty) }

    public var matchedText: String { tagPrefix == nil ? text : "" }

    public var tags: [Tag<Reminder>.ID] { tokens.compactMap { if case let .tag(tag) = $0 { tag } else { nil } } }

    public static func committingText(_ search: Self) -> Self {
        guard search.tagPrefix == nil, !search.text.trimmed.isEmpty else { return search }
        var committed = search
        committed.tokens.append(.near(search.text.trimmed))
        committed.text = ""
        return committed
    }

    public mutating func commitText() { self = Self.committingText(self) }

    public static func adding(_ search: Self, tag: Tag<Reminder>.ID) -> Self {
        var added = search
        added.tokens.append(.tag(tag))
        added.text = ""
        return added
    }

    public mutating func add(tag: Tag<Reminder>.ID) { self = Self.adding(self, tag: tag) }
}
