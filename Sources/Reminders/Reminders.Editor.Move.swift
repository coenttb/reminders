public import Models
public import Reminder

extension Reminders.Editor {
    public struct Move: Sendable {
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
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
