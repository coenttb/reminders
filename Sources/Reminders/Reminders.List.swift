public import Foundation
public import Models
public import Reminder

extension Reminders.List {
    public struct Request: Hashable, Sendable {
        public var selection: Reminders.Selection
        public var today: Range<Date>
        public var including: Reminders.Placement?
        public var limit: Int?

        public init(selection: Reminders.Selection, today: Range<Date>, including: Reminders.Placement? = nil, limit: Int? = nil) {
            self.selection = selection
            self.today = today
            self.including = including
            self.limit = limit
        }
    }
}

extension Reminders.List {
    public struct Result: Hashable, Sendable {
        public var selection: Reminders.Selection
        public var preference: Reminders.Preference
        public var rows: [Reminder]
        public var total: Int
        public var completed: Int

        public init(
            selection: Reminders.Selection,
            preference: Reminders.Preference,
            rows: [Reminder] = [],
            total: Int = 0,
            completed: Int = 0
        ) {
            self.selection = selection
            self.preference = preference
            self.rows = rows
            self.total = total
            self.completed = completed
        }
    }
}
