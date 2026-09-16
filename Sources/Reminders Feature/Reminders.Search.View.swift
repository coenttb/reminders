public import Reminders
public import Tagged
public import Foundation
public import Models
public import Reminder

extension Reminders.Search {
    public struct View {
        public var showCompleted: Bool
        public var window: Window<Query>
        public var grace: Set<Reminder.ID>
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(showCompleted: Bool, window: Window<Query>, grace: Set<Reminder.ID> = [], now: Date, calendar: Calendar, actions: Actions) {
            self.showCompleted = showCompleted
            self.window = window
            self.grace = grace
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
