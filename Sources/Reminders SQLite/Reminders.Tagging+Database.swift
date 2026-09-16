public import Models
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData
public import Tagged

extension Reminders.Tagging {
    public static func attach(_ tags: Set<Tag<Reminder>.ID>, to id: Reminder.ID, in db: Database) throws {
        for tag in tags.sorted() {
            guard let canonical = try Tag<Reminder>.Record.add(tag.rawValue, in: db) else { continue }
            let linked = try Reminders.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(canonical) }.fetchCount(db) > 0
            if !linked {
                try Reminders.Tagging.insert { Reminders.Tagging(reminderID: id, tagID: canonical) }.execute(db)
            }
        }
    }
}
