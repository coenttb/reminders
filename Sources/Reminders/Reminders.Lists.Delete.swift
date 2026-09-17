public import Models
public import Reminder

extension Reminders.Lists {
    public struct Delete: Sendable {
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Lists.Delete {
    public struct Request: Hashable, Sendable {
        public var id: Models.List<Reminder>.ID
        public var replacement: Models.List<Reminder>.ID

        public init(id: Models.List<Reminder>.ID, replacement: Models.List<Reminder>.ID) {
            self.id = id
            self.replacement = replacement
        }
    }
}
