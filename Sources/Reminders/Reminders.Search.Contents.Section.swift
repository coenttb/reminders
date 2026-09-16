public import Models
public import Reminder
public import Tagged

extension Reminders.Search.Contents {
    public struct Section: Identifiable, Hashable, Sendable {
        public var list: List<Reminder>
        public var rows: [Reminder]

        public var id: List<Reminder>.ID { list.id }

        public init(list: List<Reminder>, rows: [Reminder]) {
            self.list = list
            self.rows = rows
        }
    }
}
