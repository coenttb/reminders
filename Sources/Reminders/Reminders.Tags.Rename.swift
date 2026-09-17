public import Models
public import Reminder

extension Reminders.Tags {
    public enum Rename {
        public typealias Result = Tag<Reminder>?
        public typealias Client = Operation<Request, Result>
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
