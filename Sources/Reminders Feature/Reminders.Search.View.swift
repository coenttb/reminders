public import Reminders
public import Tagged
public import Foundation
public import Models
public import Reminder

extension Reminders.Search {
    public struct View {
        public var query: Query
        public var window: Window<Query>
        public var grace: Set<Reminder.ID>
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(query: Query, window: Window<Query>, grace: Set<Reminder.ID> = [], now: Date, calendar: Calendar, actions: Actions) {
            self.query = query
            self.window = window
            self.grace = grace
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
