public import Models
public import Reminder

extension Reminders {
    public struct Query: Hashable, Sendable {
        public var terms: [String]
        public var tags: Set<Tag<Reminder>>
        public var showCompleted: Bool

        public init(terms: [String] = [], tags: Set<Tag<Reminder>> = [], showCompleted: Bool = false) {
            self.terms = terms
            self.tags = tags
            self.showCompleted = showCompleted
        }
    }
}
