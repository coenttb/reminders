public import Foundation
public import Reminders
public import Tagged

extension Reminders.Reminder {
    /// The row being edited in place, as the app describes it: which row, when, and what it can
    /// do. Its renderer holds the draft binding.
    public struct Editor {
        public var id: Reminder.ID
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(id: Reminder.ID, now: Date, calendar: Calendar, actions: Actions) {
            self.id = id
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
