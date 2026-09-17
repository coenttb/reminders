public import Models
public import Reminder

extension Reminders.Lists {
    public enum Reorder {
        public typealias Request = [List<Reminder>.ID]
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>
    }
}
