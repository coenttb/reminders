public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension List where Element == Reminder {
    /// The stored form of a list; the color is its `0xRRGGBB` integer.
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

extension List<Reminder>.Record {
    public var list: List<Reminder> {
        List(id: id, title: title, color: color.color, position: position)
    }
}
