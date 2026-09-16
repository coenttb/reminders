public import Foundation

extension Reminders.Overview {
    public struct View {
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
