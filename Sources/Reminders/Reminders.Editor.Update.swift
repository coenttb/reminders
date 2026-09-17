public import Models
public import Reminder

extension Reminders.Editor {
    public enum Update {
        public typealias Request = Reminder
        public typealias Result = Bool
        public typealias Client = Operation<Request, Result>
    }
}
