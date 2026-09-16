public import Reminder

extension Reminder.Record.Draft {
    public var due: Reminder.Due? {
        get { dueDate.map { Reminder.Due($0, hasTime: hasTime) } }
        set {
            dueDate = newValue?.date
            hasTime = newValue?.hasTime ?? false
        }
    }
}
