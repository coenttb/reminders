public import Reminders
public import SQLiteData
public import Tagged

extension Tag {
    /// The stored form of a tag: its title is the key, case-insensitively.
    @Table("tags")
    public struct Record: Identifiable, Sendable {
        @Column(primaryKey: true)
        public var title: String

        public var id: Tag.ID { Tag.ID(title) }

        public init(_ tag: Tag) {
            title = tag.title
        }
    }
}

extension Tag.Record {
    public var tag: Tag { Tag(title: title) }
}
