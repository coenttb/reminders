public import Organizing
public import Reminders
public import Tagged

extension Reminders.Search.Results {
    public struct Section: Identifiable, Hashable, Sendable {
        public var list: List<Reminder>
        public var reminders: [Reminder]

        public var id: List<Reminder>.ID { list.id }

        public init(list: List<Reminder>, reminders: [Reminder]) {
            self.list = list
            self.reminders = reminders
        }
    }
}
