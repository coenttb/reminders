public import Reminders
public import SQLiteData
public import Tagged

extension Tag.Record {
    /// The title the tags table already uses for a title in any case; the key compares as
    /// Swift's `localizedCaseInsensitiveCompare` does, so this is the one every path that
    /// attaches a tag must use.
    public static func canonical(_ title: String) -> Select<String, Tag.Record, ()> {
        Tag.Record.where { $0.title.eq(title) }.select(\.title)
    }

    /// Adds a tag, or finds the one the title already names in any case. Returns its identifier,
    /// or nil for an empty title.
    @discardableResult
    public static func add(_ title: String, in db: Database) throws -> Tag.ID? {
        guard !title.isEmpty else { return nil }
        if let existing = try canonical(title).fetchAll(db).first { return Tag.ID(rawValue: existing) }
        try Tag.Record.insert { Tag.Record(Tag(title: title)) }.execute(db)
        return Tag.ID(title)
    }

    /// Removes the tag from every reminder that carries it, and then itself.
    public static func delete(_ id: Tag.ID) -> DeleteOf<Tag.Record> {
        Tag.Record.find(id.rawValue).delete()
    }

    /// Renames a tag everywhere it is used. Renaming onto a title another tag already has, in any
    /// case, merges into that tag; renaming only in case keeps the tag and its links. Returns
    /// the identifier the tag has afterwards, or nil when the tag is gone or the title empty.
    public static func rename(_ id: Tag.ID, to title: String, in db: Database) throws -> Tag.ID? {
        guard !title.isEmpty, let current = try canonical(id.rawValue).fetchAll(db).first.map({ Tag.ID(rawValue: $0) }) else { return nil }
        if let target = try canonical(title).fetchAll(db).first.map({ Tag.ID(rawValue: $0) }), target != current {
            for reminderID in try Reminder.Tagging.where({ $0.tagID.eq(current) }).select(\.reminderID).fetchAll(db) {
                try Reminder.Tagging.attach([target], to: reminderID, in: db)
            }
            try delete(current).execute(db)
            return target
        }
        let renamed = Tag.ID(title)
        try Tag.Record.find(current.rawValue).update { $0.title = title }.execute(db)
        // The key compares case-insensitively, so a change of case alone does not cascade to the links.
        try #sql(#"UPDATE "remindersTags" SET "tagID" = \#(renamed) WHERE "tagID" = \#(current)"#).execute(db)
        return renamed
    }
}
