public import Reminder

extension Reminder.Record.Draft {
    public init(_ reminder: Reminder, position: Int = 0) {
        self.init(
            id: reminder.id,
            listID: reminder.list,
            title: reminder.title,
            notes: reminder.notes,
            dueDate: reminder.due?.date,
            hasTime: reminder.due?.hasTime ?? false,
            flagged: reminder.flagged,
            priority: reminder.priority,
            completed: reminder.completed,
            deleted: reminder.deleted,
            position: position,
            repeats: reminder.repeats,
            created: reminder.created
        )
    }
}
