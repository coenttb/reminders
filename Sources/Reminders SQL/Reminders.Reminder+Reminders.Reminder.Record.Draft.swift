public import Reminders

extension Reminders.Reminder.Record.Draft {
    public init(_ reminder: Reminder) {
        self.init(
            id: reminder.id,
            listID: reminder.list,
            title: reminder.title,
            notes: reminder.notes,
            dueDate: reminder.due?.date,
            hasTime: reminder.due?.hasTime ?? false,
            flagged: reminder.flagged,
            priority: reminder.priority,
            status: reminder.completed ? .completed : .incomplete,
            position: reminder.position,
            location: reminder.location,
            repeats: reminder.repeats,
            created: reminder.created
        )
    }
}
