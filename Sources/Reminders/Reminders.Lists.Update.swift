public import Models
public import Reminder

extension Reminders.Lists {
    public struct Update: Sendable {
        public typealias Request = List<Reminder>
        public typealias Result = Bool
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
