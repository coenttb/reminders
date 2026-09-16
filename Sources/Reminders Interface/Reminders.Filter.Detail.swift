public import Organizing
public import Reminders
public import Tagged

extension Reminders.Filter {
    public struct Detail: Hashable, Sendable {
        public var filter: Reminders.Filter
        public var color: Color?
        public var preference: Preference
        public var rows: [Row] { didSet { ids = rows.map(\.id) } }
        public var total: Int
        public var completedCount: Int
        public private(set) var ids: [Reminder.ID]

        public init(filter: Reminders.Filter, color: Color? = nil, preference: Preference, rows: [Row] = [], total: Int = 0, completedCount: Int = 0) {
            self.filter = filter
            self.color = color
            self.preference = preference
            self.rows = rows
            self.total = total
            self.completedCount = completedCount
            self.ids = rows.map(\.id)
        }

        public var hasMore: Bool { rows.count < total }

        public var reminders: [Reminder] { rows.map(\.reminder) }
    }
}
