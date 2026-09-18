public import Models
public import Reminder
public import StructuredQueries
public import Tagged

extension Models.List<Reminder> {
    @Table("lists")
    public struct Record: Identifiable, Hashable, Sendable {
        public let id: Models.List<Reminder>.ID
        public var title: String = ""
        public var position: Int = 0

        public init(id: Models.List<Reminder>.ID, title: String = "", position: Int = 0) {
            self.id = id
            self.title = title
            self.position = position
        }
    }
}

extension Models.List<Reminder>.Record.Draft: Hashable, Sendable {}

extension Models.List<Reminder>.Record {
    public init(_ list: Models.List<Reminder>, position: Int = 0) {
        self.init(id: list.id, title: list.title, position: position)
    }

    // The list with its open count, selected from the join with its reminders.
    @Selection
    public struct Entry: Hashable, Sendable {
        public let list: Models.List<Reminder>.Record
        public let count: Int

        public init(list: Models.List<Reminder>.Record, count: Int) {
            self.list = list
            self.count = count
        }
    }
}

extension Models.List<Reminder> {
    public init(_ record: Models.List<Reminder>.Record) {
        self.init(id: record.id, title: record.title)
    }
}

extension Models.List<Reminder>.Entry {
    public init(_ entry: Models.List<Reminder>.Record.Entry) {
        self.init(list: Models.List<Reminder>(entry.list), count: entry.count)
    }
}
