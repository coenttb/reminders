import Organizing
public import Reminders
import Tagged

extension Reminders.Reminder {
    public init(_ row: Reminder.Record.Row) {
        self.init(
            id: row.reminder.id,
            list: row.reminder.listID,
            title: row.reminder.title,
            notes: row.reminder.notes,
            due: row.reminder.due,
            flagged: row.reminder.flagged,
            priority: row.reminder.priority,
            completion: row.reminder.status == .incomplete ? .incomplete : .completed,
            tags: Set(row.tags.map(Tag<Reminder>.ID.init)),
            position: row.reminder.position,
            location: row.reminder.location,
            repeats: row.reminder.repeats,
            created: row.reminder.created
        )
    }
}
