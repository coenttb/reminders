public import Models
public import Reminder

extension Reminders.Lists {
    public enum Add {
        public typealias Request = List<Reminder>
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>
    }
}
