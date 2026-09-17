public import Models
public import Reminder

extension Reminders.Editor {
    public struct Update: Sendable {
        public typealias Request = Reminder
        public typealias Result = Bool
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
