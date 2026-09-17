public import Models
public import Reminder

extension Reminders.Tags {
    public enum Suggest {
        public typealias Result = [Tag<Reminder>]
        public typealias Client = Operation<Request, Result>
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
