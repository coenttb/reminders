public import Foundation
public import Reminder
public import Tagged

extension Reminder {
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
