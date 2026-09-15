import Foundation
import FoundationEssentials_Extensions
public import Organizing
public import Reminders
import Standard_Library_Extensions
public import Tagged

extension Reminder {
    /// What the user typed into search: free text plus committed tokens.
    public struct Search: Hashable, Sendable {
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

extension Reminder.Search {
    /// A committed search term: free text the reminder must contain, or a tag it must carry.
    public enum Token: Hashable, Identifiable, Sendable {
        case near(String)
        case tag(Tag<Reminder>.ID)

        public var id: Self { self }
    }

    public var isActive: Bool { !text.isEmpty || !tokens.isEmpty }

    /// Typed `#` starts tag completion.
    public var tagPrefix: String? {
        text.removing(prefix: "#").map(String.init)
    }

    /// Whether the search names reminders at all: a tag prefix alone offers suggestions, not the
    /// whole database.
    public var matchesReminders: Bool { isActive && (tagPrefix == nil || !tokens.isEmpty) }

    /// The free text the reminders must contain; none while a tag prefix is being typed.
    public var matchedText: String { tagPrefix == nil ? text : "" }

    /// The tags already committed as tokens.
    public var tags: [Tag<Reminder>.ID] { tokens.compactMap { if case let .tag(tag) = $0 { tag } else { nil } } }

    /// Submitting the field commits the trimmed text as a near token; a tag prefix is
    /// left for the suggestions.
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
