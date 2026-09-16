public import Foundation
public import Reminders

extension Reminders.Reminder {
    public struct Form {
        public var isNew: Bool
        public var isDirty: Bool
        public var failure: String?
        public var now: Date
        public var calendar: Calendar
        public var actions: Actions

        public init(isNew: Bool, isDirty: Bool, failure: String?, now: Date, calendar: Calendar, actions: Actions) {
            self.isNew = isNew
            self.isDirty = isDirty
            self.failure = failure
            self.now = now
            self.calendar = calendar
            self.actions = actions
        }
    }
}
