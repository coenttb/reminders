public import Models
public import Reminder
public import Reminders
public import Tagged

extension Reminders.Search {
    public struct Contents: Hashable, Sendable {
        public var sections: [Section]
        public var total: Int
        public var completedCount: Int
        public var suggestions: [Tag<Reminder>]
        public var highlights: [Reminder.ID: Reminders.Highlight]

        public init(sections: [Section] = [], total: Int = 0, completedCount: Int = 0, suggestions: [Tag<Reminder>] = [], highlights: [Reminder.ID: Reminders.Highlight] = [:]) {
            self.sections = sections
            self.total = total
            self.completedCount = completedCount
            self.suggestions = suggestions
            self.highlights = highlights
        }
    }
}

extension Reminders.Search.Contents {
    public struct Section: Identifiable, Hashable, Sendable {
        public var list: Models.List<Reminder>
        public var rows: [Reminder]

        public var id: Models.List<Reminder>.ID { list.id }

        public init(list: Models.List<Reminder>, rows: [Reminder]) {
            self.list = list
            self.rows = rows
        }
    }

    public var shown: Int { sections.reduce(0) { $0 + $1.rows.count } }

    public init(_ page: Reminders.Page?, lists: [Models.List<Reminder>.Entry], suggestions: [Tag<Reminder>]) {
        self.init(total: page?.total ?? 0, completedCount: page?.completed ?? 0, suggestions: suggestions, highlights: page?.highlights ?? [:])
        // The page is already folded list by list; a section whose list is gone is dropped with it.
        sections = (page?.sections ?? []).compactMap { section in
            guard case let .list(id) = section.key, let list = lists.first(where: { $0.id == id })?.list else { return nil }
            return Section(list: list, rows: section.rows)
        }
    }
}
