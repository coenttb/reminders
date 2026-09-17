public import Models
public import Reminder

extension Reminders.Tags {
    public struct Create: Sendable {
        public typealias Request = String
        public typealias Result = Tag<Reminder>?
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
