public import Models
public import Reminder
import Reminders
public import Reminders_SQL
public import SQLiteData
import Tagged

extension Tag<Reminder>.Record {
    @discardableResult
    public static func add(_ title: String, in db: Database) throws -> Tag<Reminder>? {
        guard !title.isEmpty else { return nil }
        if let existing = try canonical(title).fetchAll(db).first { return Tag<Reminder>(existing) }
        try Tag<Reminder>.Record.insert { Tag<Reminder>.Record(Tag<Reminder>(title)) }.execute(db)
        return Tag<Reminder>(title)
    }

    public static func rename(_ id: Tag<Reminder>, to title: String, in db: Database) throws -> Tag<Reminder>? {
        guard !title.isEmpty, let stored = try canonical(id.rawValue).fetchAll(db).first else { return nil }
        let current: Tag<Reminder> = Tag<Reminder>(stored)
        if let existing = try canonical(title).fetchAll(db).first, existing != stored {
            let target: Tag<Reminder> = Tag<Reminder>(existing)
            let merge = Reminders.Tagging.insert {
                ($0.reminderID, $0.tagID)
            } select: {
                Reminders.Tagging.where { $0.tagID.eq(current) }.select { ($0.reminderID, target) }
            } onConflict: {
                ($0.reminderID, $0.tagID)
            }
            try merge.execute(db)
            try delete(current).execute(db)
            return target
        }
        let renamed: Tag<Reminder> = Tag<Reminder>(title)
        try Tag<Reminder>.Record.find(current.rawValue).update { $0.title = title }.execute(db)
        try Reminders.Tagging.where { $0.tagID.eq(current) }.update { $0.tagID = renamed }.execute(db)
        return renamed
    }
}
