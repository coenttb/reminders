public import Models
public import Reminder

extension Reminders.Editor {
    public enum Move {
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>
    }
}

extension Reminders.Editor.Move {
    public struct Request: Hashable, Sendable {
        public var ids: [Reminder.ID]
        public var filter: Reminders.Filter

        public init(ids: [Reminder.ID], filter: Reminders.Filter) {
            self.ids = ids
            self.filter = filter
        }
    }
}
