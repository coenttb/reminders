public import Models
public import Reminder

extension Reminders {
    public struct Retrieve: Sendable {
        public typealias Request = Reminder.ID
        public typealias Result = Reminders.Placement
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
