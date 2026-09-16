public import Foundation
public import Reminders

extension Reminders.Reminder {
    /// The sheet that edits one reminder in full, as the screen describes it: what it shows and
    /// what it can do. Its renderer holds the draft and the tags.
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
