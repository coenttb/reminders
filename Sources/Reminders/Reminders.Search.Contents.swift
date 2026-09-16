public import Models
public import Reminder

extension Reminders.Search {
    public struct Contents: Hashable, Sendable {
        public var sections: [Section]
        public var total: Int
        public var completedCount: Int
        public var suggestions: [Tag<Reminder>]

        public init(sections: [Section] = [], total: Int = 0, completedCount: Int = 0, suggestions: [Tag<Reminder>] = []) {
            self.sections = sections
            self.total = total
            self.completedCount = completedCount
            self.suggestions = suggestions
        }
    }
}

extension Reminders.Search.Contents {
    public var shown: Int { sections.reduce(0) { $0 + $1.rows.count } }
}
