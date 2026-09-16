public import Organizing
public import Reminders
public import SQLiteData
public import Tagged

extension Reminder.Tagging {
    public static func attach(_ tags: Set<Tag<Reminder>.ID>, to id: Reminder.ID, in db: Database) throws {
        for tag in tags.sorted() {
            guard let canonical = try Tag<Reminder>.Record.add(tag.rawValue, in: db) else { continue }
            let linked = try Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.eq(canonical) }.fetchCount(db) > 0
            if !linked {
                try Reminder.Tagging.insert { Reminder.Tagging(reminderID: id, tagID: canonical) }.execute(db)
            }
        }
    }

    public static func detach(_ tags: Set<Tag<Reminder>.ID>, from id: Reminder.ID) -> DeleteOf<Reminder.Tagging> {
        Reminder.Tagging.where { $0.reminderID.eq(id) && $0.tagID.in(tags) }.delete()
    }
}
