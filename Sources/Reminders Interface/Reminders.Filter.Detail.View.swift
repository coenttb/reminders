public import Foundation
public import Reminders
public import Tagged

extension Reminders.Filter.Detail {
    /// One filter's screen as the app describes it: its title, the row being edited, and what it
    /// can do. Its renderer holds the contents and the draft binding.
    public struct View {
        public var title: String
        public var editing: Reminder.ID?
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(title: String, editing: Reminder.ID?, now: Date, calendar: Calendar, actions: Actions) {
            self.title = title
            self.editing = editing
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
