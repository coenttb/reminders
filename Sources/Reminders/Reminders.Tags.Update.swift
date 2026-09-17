public import Models
public import Reminder

extension Reminders.Tags.Update {
    public struct Request: Hashable, Sendable {
        public var tag: Tag<Reminder>
        public var title: String

        public init(tag: Tag<Reminder>, title: String) {
            self.tag = tag
            self.title = title
        }
    }
}
