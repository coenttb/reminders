public import Organizing
public import Reminders
public import Tagged

extension Reminder.Search {
    /// The search as read from the database: the first matches grouped under their lists, open
    /// ones first and by due date, how many matches there are in all, the number of completed
    /// matches whether or not they are shown, and the tags completing a typed prefix.
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

        /// How many matches are shown.
        public var shown: Int { sections.reduce(0) { $0 + $1.reminders.count } }

        /// Whether the search has matches beyond the ones read.
        public var hasMore: Bool { shown < total }

        /// The matches in one list.
        public struct Section: Identifiable, Hashable, Sendable {
            public var list: List<Reminder>
            public var reminders: [Reminder]

            public var id: List<Reminder>.ID { list.id }

            public init(list: List<Reminder>, reminders: [Reminder]) {
                self.list = list
                self.reminders = reminders
            }
        }

        public var reminders: [Reminder] { sections.flatMap(\.reminders) }
    }
}
