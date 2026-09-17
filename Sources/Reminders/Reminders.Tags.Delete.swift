public import Models
public import Reminder

extension Reminders.Tags {
    public struct Delete: Sendable {
        public typealias Request = Tag<Reminder>
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}
