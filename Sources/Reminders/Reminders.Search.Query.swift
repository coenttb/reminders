import Foundation
import FoundationEssentials_Extensions
public import Models
public import Reminder
import Standard_Library_Extensions

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

    public var tags: [Tag<Reminder>] { tokens.compactMap { if case let .tag(tag) = $0 { tag } else { nil } } }
}
