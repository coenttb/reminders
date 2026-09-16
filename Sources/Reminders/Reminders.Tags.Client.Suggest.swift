public import Models
public import Reminder

extension Reminders.Tags.Client {
    public struct Suggest: Operation {
        public typealias Result = [Tag<Reminder>]

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Tags.Client.Suggest {
    public struct Request: Hashable, Sendable {
        public var prefix: String
        public var excluding: Set<Tag<Reminder>>

        public init(prefix: String, excluding: Set<Tag<Reminder>> = []) {
            self.prefix = prefix
            self.excluding = excluding
        }
    }
}
