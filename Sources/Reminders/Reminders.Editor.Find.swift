public import Models
public import Reminder

extension Reminders.Editor {
    public enum Find {
        public typealias Request = Reminder.ID
        public typealias Result = Reminders.Placement?
        public typealias Client = Operation<Request, Result>
    }
}
