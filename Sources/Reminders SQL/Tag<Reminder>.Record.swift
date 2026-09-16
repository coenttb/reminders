public import Models
public import Reminder
public import StructuredQueries
public import Tagged

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
        self.init(title: tag.title)
    }
}

extension Tag<Reminder>.Record {
    public static func canonical(_ title: String) -> Select<String, Tag<Reminder>.Record, ()> {
        Tag<Reminder>.Record.where { $0.title.eq(title) }.select(\.title)
    }

    public static func delete(_ id: Tag<Reminder>.ID) -> DeleteOf<Tag<Reminder>.Record> {
        Tag<Reminder>.Record.find(id.rawValue).delete()
    }

}
