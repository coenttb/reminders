public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension List where Element == Reminder {
    @Table("lists")
    public struct Record: Identifiable, Sendable {
        public let id: List<Reminder>.ID
        public var title: String
        public var color: Color.Hex
        public var position: Int

        public init(_ list: List<Reminder>) {
            id = list.id
            title = list.title
            color = Color.Hex(list.color)
            position = list.position
        }
    }
}

extension List<Reminder> {
    public init(_ record: List<Reminder>.Record) {
        self.init(id: record.id, title: record.title, color: Color(record.color), position: record.position)
    }
}

extension List<Reminder>.Record {
    public var list: List<Reminder> { List(self) }
}
