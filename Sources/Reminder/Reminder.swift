public import Foundation
public import List
public import Tagged

public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: Tagged<Reminder, UUID>
    public var list: List<Reminder>.ID
    public var title: String
    public var completed: Bool
    public var created: Date

    public init(id: ID, list: List<Reminder>.ID, title: String = "", completed: Bool = false, created: Date) {
        self.id = id
        self.list = list
        self.title = title
        self.completed = completed
        self.created = created
    }
}

extension Reminder {
    // A reminder before it has an identity and a creation time: what `create` is called with; storage mints both.
    public struct Draft: Hashable, Sendable {
        public var list: List<Reminder>.ID
        public var title: String
        public var completed: Bool

        public init(list: List<Reminder>.ID, title: String = "", completed: Bool = false) {
            self.list = list
            self.title = title
            self.completed = completed
        }

        public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
    }

    public init(id: ID, _ draft: Draft, created: Date) {
        self.init(id: id, list: draft.list, title: draft.title, completed: draft.completed, created: created)
    }

    public var draft: Draft {
        get { Draft(list: list, title: title, completed: completed) }
        set {
            list = newValue.list
            title = newValue.title
            completed = newValue.completed
        }
    }

    public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
}
