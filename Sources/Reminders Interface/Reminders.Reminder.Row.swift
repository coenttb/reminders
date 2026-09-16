public import Foundation
public import Reminders

extension Reminders.Reminder {
    /// A reminder's row as the app describes it: when it is read and what it can do. Its renderer
    /// holds the record row.
    public struct Row {
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(now: Date, calendar: Calendar, actions: Actions) {
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
