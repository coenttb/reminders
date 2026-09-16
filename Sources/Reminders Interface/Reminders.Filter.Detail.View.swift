public import Foundation
public import Reminder
public import Reminders
public import Tagged

extension Reminders.Filter.Detail {
    public struct View {
        public var filter: Reminders.Filter
        public var window: Window<Reminders.Filter>
        public var editing: Reminder.ID?
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(filter: Reminders.Filter, window: Window<Reminders.Filter>, editing: Reminder.ID?, now: Date, calendar: Calendar, actions: Actions) {
            self.filter = filter
            self.window = window
            self.editing = editing
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
