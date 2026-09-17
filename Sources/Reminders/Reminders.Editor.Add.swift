public import Models
public import Reminder

extension Reminders.Editor {
    public enum Add {
        public typealias Request = Reminder
        public typealias Result = Bool
        public typealias Client = Operation<Request, Result>
    }
}
