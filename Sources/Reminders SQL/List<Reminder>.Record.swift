public import Interface_Macro
public import List
public import Reminder
public import StructuredQueries
public import Tagged

extension List<Reminder> {
    @Table("lists")
    @Memberwise
    public struct Record: Identifiable, Hashable, Sendable {
        public let id: List<Reminder>.ID
        public var title: String = ""
        public var position: Int = 0
    }
}

extension List<Reminder>.Record.Draft: Hashable, Sendable {}

extension List<Reminder>.Record {
    public init(_ list: List<Reminder>, position: Int = 0) {
        self.init(id: list.id, title: list.title, position: position)
    }

    // The list with its open count, selected from the join with its reminders.
    @Selection
    @Memberwise
    public struct Entry: Hashable, Sendable {
        public let list: List<Reminder>.Record
        public let count: Int
    }
}

extension List<Reminder> {
    public init(_ record: List<Reminder>.Record) {
        self.init(id: record.id, title: record.title)
    }
}

extension List<Reminder>.Entry {
    public init(_ entry: List<Reminder>.Record.Entry) {
        self.init(list: List<Reminder>(entry.list), count: entry.count)
    }
}
