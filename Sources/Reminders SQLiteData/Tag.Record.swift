public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension Tag where Element == Reminder {
    @Table("tags")
    public struct Record: Identifiable, Sendable {
        @Column(primaryKey: true)
        public var title: String

        public var id: Tag<Reminder>.ID { Tag<Reminder>.ID(title) }

        init(title: String) {
            self.title = title
        }
    }
}

extension Tag<Reminder>.Record {
    public init(_ tag: Tag<Reminder>) {
        self.init(title: tag.title)
    }
}

extension Tag<Reminder> {
    public init(_ record: Tag<Reminder>.Record) {
        self.init(title: record.title)
    }
}
