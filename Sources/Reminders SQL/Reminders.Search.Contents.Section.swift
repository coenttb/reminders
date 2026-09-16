public import Organizing
public import Reminders
public import Reminders_Interface
public import Tagged

extension Reminders.Search.Contents {
    public struct Section: Identifiable, Hashable, Sendable {
        public var list: List<Reminder>.Record
        public var rows: [Reminder.Record.Row]

        public var id: List<Reminder>.ID { list.id }

        public init(list: List<Reminder>.Record, rows: [Reminder.Record.Row]) {
            self.list = list
            self.rows = rows
        }
    }
}
