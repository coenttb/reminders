public import Models
public import Reminder

extension Reminders.Lists {
    public struct Reorder: Sendable {
        public typealias Request = [Models.List<Reminder>.ID]
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
