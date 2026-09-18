import Models
public import Reminder
import Tagged

extension Reminder {
    public init(_ row: Reminder.Record.Row) {
        self.init(
            id: row.reminder.id,
            list: row.reminder.listID,
            title: row.reminder.title,
            notes: row.reminder.notes,
            due: row.reminder.due,
            repeats: row.reminder.repeats,
            priority: row.reminder.priority,
            flagged: row.reminder.flagged,
            completed: row.reminder.completed,
            deleted: row.reminder.deleted,
            tags: Set(row.tags.map { Tag<Reminder>($0) }),
            created: row.reminder.created
        )
    }
}
