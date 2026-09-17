public import Models
public import Reminder

extension Reminders.Reorder {
    public struct Request: Hashable, Sendable {
        public var ids: [Reminder.ID]
        public var filter: Reminders.Filter

        public init(ids: [Reminder.ID], in filter: Reminders.Filter) {
            self.ids = ids
            self.filter = filter
        }
    }
}
