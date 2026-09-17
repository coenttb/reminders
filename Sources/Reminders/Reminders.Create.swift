public import Models
public import Reminder

extension Reminders.Create {
    public struct Request: Hashable, Sendable {
        public var reminder: Reminder
        public var below: Reminders.Placement?

        public init(_ reminder: Reminder, below: Reminders.Placement? = nil) {
            self.reminder = reminder
            self.below = below
        }
    }
}
