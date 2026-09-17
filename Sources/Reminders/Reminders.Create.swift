public import Models
public import Reminder

extension Reminders {
    public struct Create: Sendable {
        public typealias Result = Reminders.Placement
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

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
