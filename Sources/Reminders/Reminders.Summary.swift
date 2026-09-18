public import Models
public import Reminder

extension Reminders {
    public struct Summary: Hashable, Sendable {
        public var lists: [Models.List<Reminder>.Entry]

        public init(lists: [Models.List<Reminder>.Entry] = []) {
            self.lists = lists
        }
    }
}
