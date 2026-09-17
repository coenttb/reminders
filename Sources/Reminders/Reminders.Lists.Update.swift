public import Models
public import Reminder

extension Reminders.Lists {
    public enum Update {
        public typealias Request = List<Reminder>
        public typealias Result = Bool
        public typealias Client = Operation<Request, Result>
    }
}
