public import Foundation
public import Reminder

extension Reminder {
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
