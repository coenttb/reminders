public import Models
public import Reminder

extension Reminders.Tags.List {
    public struct Request: Hashable, Sendable {
        public var prefix: String
        public var excluding: Set<Tag<Reminder>>

        public init(prefix: String, excluding: Set<Tag<Reminder>> = []) {
            self.prefix = prefix
            self.excluding = excluding
        }
    }
}
