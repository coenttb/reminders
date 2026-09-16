public import Foundation

extension Reminders.Reminder: Reminders.Reminder.Fields {
    public var dueDate: Date? {
        get { due?.date }
        set { due = newValue.map { Due($0, hasTime: due?.hasTime ?? false) } }
    }

    public var hasTime: Bool {
        get { due?.hasTime ?? false }
        set { due = due.map { Due($0.date, hasTime: newValue) } }
    }

    public var completed: Bool { completion == .completed }
}
