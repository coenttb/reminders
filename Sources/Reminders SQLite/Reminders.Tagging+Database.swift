public import Models
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Tag<Reminder>.Record {
    // One tag per title in any case: an existing twin wins over the spelling being added.
    @discardableResult
    public static func add(_ title: String, in db: Database) throws -> Tag<Reminder>? {
        guard !title.isEmpty else { return nil }
        let twins = Tag<Reminder>.Record.where { $0.title.eq(title) }.select(\.title)
        if let existing = try twins.fetchAll(db).first { return Tag<Reminder>(existing) }
        try Tag<Reminder>.Record.insert { Tag<Reminder>.Record(Tag<Reminder>(title)) }.execute(db)
        return Tag<Reminder>(title)
    }
}

extension Reminders.Tagging {
    public static func attach(_ tags: Set<Tag<Reminder>>, to id: Reminder.ID, in db: Database) throws {
        for tag in tags.sorted() {
            guard let canonical = try Tag<Reminder>.Record.add(tag.rawValue, in: db) else { continue }
            let linked = try Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(canonical) }.fetchCount(db) > 0
            if !linked {
                try Reminders.Tagging.insert { Reminders.Tagging(reminderID: id, tagID: canonical) }.execute(db)
            }
        }
    }
}
