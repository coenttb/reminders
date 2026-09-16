public import Organizing
public import Reminders
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Tag<Reminder>.Record {
    @discardableResult
    public static func add(_ title: String, in db: Database) throws -> Tag<Reminder>.ID? {
        guard !title.isEmpty else { return nil }
        if let existing = try canonical(title).fetchAll(db).first { return Tag<Reminder>.ID(existing) }
        try Tag<Reminder>.Record.insert { Tag<Reminder>.Record(Tag(title: title)) }.execute(db)
        return Tag<Reminder>.ID(title)
    }

    public static func rename(_ id: Tag<Reminder>.ID, to title: String, in db: Database) throws -> Tag<Reminder>.ID? {
        guard !title.isEmpty, let stored = try canonical(id.rawValue).fetchAll(db).first else { return nil }
        let current: Tag<Reminder>.ID = Tag<Reminder>.ID(rawValue: stored)
        if let existing = try canonical(title).fetchAll(db).first, existing != stored {
            let target: Tag<Reminder>.ID = Tag<Reminder>.ID(rawValue: existing)
            for reminderID in try Reminders.Tagging.where({ $0.tagID.eq(current) }).select(\.reminderID).fetchAll(db) {
                try Reminders.Tagging.attach([target], to: reminderID, in: db)
            }
            try delete(current).execute(db)
            return target
        }
        let renamed: Tag<Reminder>.ID = Tag<Reminder>.ID(rawValue: title)
        try Tag<Reminder>.Record.find(current.rawValue).update { $0.title = title }.execute(db)
        try Reminders.Tagging.where { $0.tagID.eq(current) }.update { $0.tagID = renamed }.execute(db)
        return renamed
    }
}
