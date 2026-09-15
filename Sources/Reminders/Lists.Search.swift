import Foundation
import FoundationEssentials_Extensions
public import Tagged

extension Lists {
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

extension Lists.Search {
    /// A committed search term: free text the reminder must contain, or a tag it must carry.
    public enum Token: Hashable, Identifiable, Sendable {
        case near(String)
        case tag(Tag.ID)

        public var id: Self { self }
    }

    public var isActive: Bool { !text.isEmpty || !tokens.isEmpty }

    /// Typed `#` starts tag completion.
    public var tagPrefix: String? {
        text.hasPrefix("#") ? String(text.dropFirst()) : nil
    }

    /// Whether the search names reminders at all: a tag prefix alone offers suggestions, not the
    /// whole database.
    public var matchesReminders: Bool { isActive && (tagPrefix == nil || !tokens.isEmpty) }

    /// The free text the reminders must contain; none while a tag prefix is being typed.
    public var matchedText: String { tagPrefix == nil ? text : "" }

    /// The tags already committed as tokens.
    public var tags: [Tag.ID] { tokens.compactMap { if case let .tag(tag) = $0 { tag } else { nil } } }

    /// Submitting the field commits the trimmed text as a near token; a tag prefix is
    /// left for the suggestions.
    public mutating func commitText() {
        guard tagPrefix == nil, !text.trimmed.isEmpty else { return }
        tokens.append(.near(text.trimmed))
        text = ""
    }

    public mutating func add(tag: Tag.ID) {
        tokens.append(.tag(tag))
        text = ""
    }
}

extension Lists.Search {
    /// The search as read from the database: the matches grouped under their lists, open ones
    /// first and by due date, the number of completed matches whether or not they are shown,
    /// and the tags completing a typed prefix.
    public struct Results: Hashable, Sendable {
        public var sections: [Section]
        public var completedCount: Int
        public var suggestions: [Tag]

        public init(sections: [Section] = [], completedCount: Int = 0, suggestions: [Tag] = []) {
            self.sections = sections
            self.completedCount = completedCount
            self.suggestions = suggestions
        }

        /// The matches in one list.
        public struct Section: Identifiable, Hashable, Sendable {
            public var list: Reminder.List
            public var reminders: [Reminder]

            public var id: Reminder.List.ID { list.id }

            public init(list: Reminder.List, reminders: [Reminder]) {
                self.list = list
                self.reminders = reminders
            }
        }

        public var reminders: [Reminder] { sections.flatMap(\.reminders) }
    }
}
