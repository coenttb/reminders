public import Models
public import Reminder

extension Reminders.Editor {
    public enum Delete {
        public typealias Request = Reminder.ID
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>
    }
}
