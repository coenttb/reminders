public import Models
public import Reminder

extension Reminders {
    public struct Complete: Sendable {
        public typealias Request = Reminder.ID
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
