public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension Tag<Reminder>.Record {
    /// The title the tags table already uses for a title in any case; the key compares as
    /// Swift's `localizedCaseInsensitiveCompare` does, so this is the one every path that
    /// attaches a tag must use.
    public static func canonical(_ title: String) -> Select<String, Tag<Reminder>.Record, ()> {
        Tag<Reminder>.Record.where { $0.title.eq(title) }.select(\.title)
    }

    /// Adds a tag, or finds the one the title already names in any case. Returns its identifier,
    /// or nil for an empty title.
    @discardableResult
    public static func add(_ title: String, in db: Database) throws -> Tag<Reminder>.ID? {
        guard !title.isEmpty else { return nil }
        if let existing = try canonical(title).fetchAll(db).first { return Tag<Reminder>.ID(existing) }
        try Tag<Reminder>.Record.insert { Tag<Reminder>.Record(Tag(title: title)) }.execute(db)
        return Tag<Reminder>.ID(title)
    }

    /// Removes the tag from every reminder that carries it, and then itself.
    public static func delete(_ id: Tag<Reminder>.ID) -> DeleteOf<Tag<Reminder>.Record> {
        Tag<Reminder>.Record.find(id.rawValue).delete()
    }

    /// Renames a tag everywhere it is used. Renaming onto a title another tag already has, in any
    /// case, merges into that tag; renaming only in case keeps the tag and its links. Returns
    /// the identifier the tag has afterwards, or nil when the tag is gone or the title empty.
    public static func rename(_ id: Tag<Reminder>.ID, to title: String, in db: Database) throws -> Tag<Reminder>.ID? {
        guard !title.isEmpty, let stored = try canonical(id.rawValue).fetchAll(db).first else { return nil }
        // Tagged also offers a failable `init?(_:)` from `LosslessStringConvertible`; the annotation picks the plain one.
        let current: Tag<Reminder>.ID = Tag<Reminder>.ID(rawValue: stored)
        if let existing = try canonical(title).fetchAll(db).first, existing != stored {
            let target: Tag<Reminder>.ID = Tag<Reminder>.ID(rawValue: existing)
            for reminderID in try Reminder.Tagging.where({ $0.tagID.eq(current) }).select(\.reminderID).fetchAll(db) {
                try Reminder.Tagging.attach([target], to: reminderID, in: db)
            }
            try delete(current).execute(db)
            return target
        }
        let renamed: Tag<Reminder>.ID = Tag<Reminder>.ID(rawValue: title)
        try Tag<Reminder>.Record.find(current.rawValue).update { $0.title = title }.execute(db)
        // The key compares case-insensitively, so a change of case alone does not cascade to the links.
        try Reminder.Tagging.where { $0.tagID.eq(current) }.update { $0.tagID = renamed }.execute(db)
        return renamed
    }
}
