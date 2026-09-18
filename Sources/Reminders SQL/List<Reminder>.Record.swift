public import Foundation
public import Models
public import Reminder
public import StructuredQueries
public import Tagged

extension Models.List<Reminder> {
    @Table("lists")
    public struct Record: Identifiable, Hashable, Sendable {
        public let id: Models.List<Reminder>.ID
        public var title: String = ""
        public var color: Color.Hex = Color.Hex(Color.default)
        public var position: Int = 0
        // A deleted list waits in Recently Deleted with its reminders, until one of them is recovered or thirty days pass.
        public var deleted: Date?

        public init(id: Models.List<Reminder>.ID, title: String = "", color: Color.Hex = Color.Hex(Color.default), position: Int = 0, deleted: Date? = nil) {
            self.id = id
            self.title = title
            self.color = color
            self.position = position
            self.deleted = deleted
        }
    }
}

extension Models.List<Reminder>.Record.Draft: Hashable, Sendable {}

extension Models.List<Reminder>.Record {
    public init(_ list: Models.List<Reminder>, position: Int = 0) {
        self.init(id: list.id, title: list.title, color: Color.Hex(list.color), position: position)
    }
}

extension Models.List<Reminder> {
    public init(_ record: Models.List<Reminder>.Record) {
        self.init(id: record.id, title: record.title, color: Color(record.color))
    }
}

extension Models.List<Reminder>.Entry {
    public init(_ entry: Models.List<Reminder>.Record.Entry) {
        self.init(list: Models.List<Reminder>(entry.list), count: entry.count)
    }
}
