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

        public init(sections: [Section] = [], total: Int = 0, completedCount: Int = 0, suggestions: [Tag<Reminder>] = []) {
            self.sections = sections
            self.total = total
            self.completedCount = completedCount
            self.suggestions = suggestions
        }
    }
}

extension Reminders.Search.Contents {
    public struct Section: Identifiable, Hashable, Sendable {
        public var list: List<Reminder>
        public var rows: [Reminder]

        public var id: List<Reminder>.ID { list.id }

        public init(list: List<Reminder>, rows: [Reminder]) {
            self.list = list
            self.rows = rows
        }
    }

    public var shown: Int { sections.reduce(0) { $0 + $1.rows.count } }

    public init(_ page: Reminders.Listing.Page?, lists: [List<Reminder>.Entry], suggestions: [Tag<Reminder>]) {
        self.init(total: page?.total ?? 0, completedCount: page?.completed ?? 0, suggestions: suggestions)
        for row in page?.rows ?? [] {
            if sections.last?.id == row.list {
                sections[sections.count - 1].rows.append(row)
            } else if let list = lists.first(where: { $0.id == row.list })?.list {
                sections.append(Section(list: list, rows: [row]))
            }
        }
    }
}
