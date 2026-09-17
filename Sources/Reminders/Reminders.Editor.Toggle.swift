public import Models
public import Reminder

extension Reminders.Editor {
    public enum Toggle {
        public typealias Request = Reminder.ID
        public typealias Result = Bool?
        public typealias Client = Operation<Request, Result>
    }
}
