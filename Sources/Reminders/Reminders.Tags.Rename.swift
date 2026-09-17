public import Models
public import Reminder

extension Reminders.Tags {
    public struct Rename: Sendable {
        public typealias Result = Tag<Reminder>?
        public typealias Client = Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Tags.Rename {
    public struct Request: Hashable, Sendable {
        public var tag: Tag<Reminder>
        public var title: String

        public init(tag: Tag<Reminder>, title: String) {
            self.tag = tag
            self.title = title
        }
    }
}
