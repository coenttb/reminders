public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension Tag where Element == Reminder {
    /// The stored form of a tag: its title is the key, case-insensitively as Swift compares.
    @Table("tags")
    public struct Record: Identifiable, Sendable {
        @Column(primaryKey: true)
        public var title: String

        public var id: Tag<Reminder>.ID { Tag<Reminder>.ID(title) }

        public init(_ tag: Tag<Reminder>) {
            title = tag.title
        }
    }
}

extension Tag<Reminder>.Record {
    public var tag: Tag<Reminder> { Tag(title: title) }
}
