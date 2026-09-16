public import Organizing
public import Reminders
public import Tagged

extension Reminders.Search {
    public struct Results: Hashable, Sendable {
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

        public var shown: Int { sections.reduce(0) { $0 + $1.reminders.count } }

        public var hasMore: Bool { shown < total }

        public var reminders: [Reminder] { sections.flatMap(\.reminders) }
    }
}
