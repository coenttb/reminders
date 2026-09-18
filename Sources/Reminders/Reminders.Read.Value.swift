public import List
public import Reminder

extension Reminders.Read {
    public struct Value: Hashable, Sendable {
        public var lists: [List<Reminder>.Entry]

        public init(lists: [List<Reminder>.Entry] = []) {
            self.lists = lists
        }
    }
}
