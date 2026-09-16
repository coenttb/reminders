public import Models
public import Reminder

extension Reminders.Tags.Client {
    public struct Rename: Operation {
        public typealias Result = Tag<Reminder>?

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Tags.Client.Rename {
    public struct Request: Hashable, Sendable {
        public var tag: Tag<Reminder>
        public var title: String

        public init(tag: Tag<Reminder>, title: String) {
            self.tag = tag
            self.title = title
        }
    }
}
