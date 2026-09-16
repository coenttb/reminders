public import Models
public import Reminder
public import StructuredQueries
import Tagged

extension Tag<Reminder> {
    @Table("tags")
    public struct Record: Hashable, Sendable {
        @Column(primaryKey: true)
        public var title: String

        init(title: String) {
            self.title = title
        }
    }
}

extension Tag<Reminder>.Record {
    public init(_ tag: Tag<Reminder>) {
        self.init(title: tag.rawValue)
    }
}

extension Tag<Reminder> {
    public init(_ record: Tag<Reminder>.Record) {
        self.init(record.title)
    }
}

extension Tag<Reminder>.Entry {
    public init(_ entry: Tag<Reminder>.Record.Entry) {
        self.init(tag: Tag<Reminder>(entry.tag), count: entry.count)
    }
}

extension Tag<Reminder>.Record {
    public static func canonical(_ title: String) -> Select<String, Tag<Reminder>.Record, ()> {
        Tag<Reminder>.Record.where { $0.title.eq(title) }.select(\.title)
    }

    public static func delete(_ id: Tag<Reminder>) -> DeleteOf<Tag<Reminder>.Record> {
        Tag<Reminder>.Record.find(id.rawValue).delete()
    }

}
