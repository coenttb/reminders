public import Models
public import Reminder

extension Reminders.Tags {
    public struct Suggest: Sendable {
        public typealias Result = [Tag<Reminder>]
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Tags.Suggest {
    public struct Request: Hashable, Sendable {
        public var prefix: String
        public var excluding: Set<Tag<Reminder>>

        public init(prefix: String, excluding: Set<Tag<Reminder>> = []) {
            self.prefix = prefix
            self.excluding = excluding
        }
    }
}
