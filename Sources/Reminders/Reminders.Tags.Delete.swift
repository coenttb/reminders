public import Models
public import Reminder

extension Reminders.Tags {
    public enum Delete {
        public typealias Request = Tag<Reminder>
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>
    }
}
