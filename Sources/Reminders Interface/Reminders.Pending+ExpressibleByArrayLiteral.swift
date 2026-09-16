public import Reminders
public import Tagged

extension Reminders.Pending: ExpressibleByArrayLiteral {
    public init(arrayLiteral ids: Reminder.ID...) {
        self.init(Set(ids))
    }
}
