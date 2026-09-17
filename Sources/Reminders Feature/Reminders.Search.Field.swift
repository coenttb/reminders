import Foundation
import FoundationEssentials_Extensions
public import Models
public import Reminder
public import Reminders
import Standard_Library_Extensions

extension Reminders.Search {
    public struct Field: Hashable, Sendable {
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

extension Reminders.Search.Field {
    public enum Token: Hashable, Sendable {
        case near(String)
        case tag(Tag<Reminder>)
    }
}

extension Reminders.Search.Field.Token: Identifiable {
    public var id: Self { self }
}

extension Reminders.Search.Field {
    public var isActive: Bool { !text.isEmpty || !tokens.isEmpty }

    public var tagPrefix: String? { text.removing(prefix: "#").map(String.init) }

    public var tags: Set<Tag<Reminder>> { Set(tokens.compactMap { if case let .tag(tag) = $0 { tag } else { nil } }) }

    public var terms: [String] { tokens.compactMap { if case let .near(text) = $0 { text } else { nil } } }

    public var query: Reminders.Search.Query {
        Reminders.Search.Query(terms: terms, tags: tags, showCompleted: showCompleted)
    }

    public var selection: Reminders.Selection? {
        guard isActive, tagPrefix == nil || !tokens.isEmpty else { return nil }
        var query = query
        if tagPrefix == nil, !text.isEmpty { query.terms.append(text) }
        return .search(query)
    }

    public var suggestions: Reminders.Tags.List.Request {
        Reminders.Tags.List.Request(prefix: tagPrefix ?? "", excluding: tags)
    }

    public mutating func commitText() {
        guard tagPrefix == nil, !text.trimmed.isEmpty else { return }
        tokens.append(.near(text.trimmed))
        text = ""
    }

    public mutating func add(tag: Tag<Reminder>) {
        tokens.append(.tag(tag))
        text = ""
    }
}
