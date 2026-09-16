import Models
public import Reminder
import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record.TableColumns {
    public var tagTitles: some QueryExpression<[String].JSONRepresentation> {
        Reminders.Tagging
            .where { $0.reminderID.eq(id) }
            .join(Tag<Reminder>.Record.all) { $1.title.eq($0.tagID.text) }
            .select { $1.title.jsonGroupArray(order: $1.title) }
    }
}
