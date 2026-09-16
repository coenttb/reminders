public import Foundation
public import Reminder
public import Tagged

extension Reminder {
    public struct Editor {
        public var id: Reminder.ID
        public var completed: Bool
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(id: Reminder.ID, completed: Bool, now: Date, calendar: Calendar, actions: Actions) {
            self.id = id
            self.completed = completed
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
