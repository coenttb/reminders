import Organizing
public import Reminders
public import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminders.Reminder.Record.TableColumns {
    /// The titles of this reminder's tags as one JSON array, in title order.
    public var tags: some QueryExpression<[String].JSONRepresentation> {
        Reminders.Tagging
            .where { $0.reminderID.eq(id) }
            .join(Tag<Reminder>.Record.all) { $1.title.eq($0.tagID.text) }
            .select { $1.title.jsonGroupArray(order: $1.title) }
    }
}
