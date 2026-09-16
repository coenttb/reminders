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
            due: row.reminder.dueDate.map { Reminder.Due($0, hasTime: row.reminder.hasTime) },
            flagged: row.reminder.flagged,
            priority: row.reminder.priority,
            completion: row.reminder.status == .incomplete ? .incomplete : .completed,
            tags: Set(row.tags.map { Tag<Reminder>.ID($0) }),
            position: row.reminder.position,
            location: row.reminder.location,
            repeats: row.reminder.repeats,
            created: row.reminder.created
        )
    }
}
