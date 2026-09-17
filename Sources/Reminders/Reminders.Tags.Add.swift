public import Models
public import Reminder

extension Reminders.Tags {
    public enum Add {
        public typealias Request = String
        public typealias Result = Tag<Reminder>?
        public typealias Client = Operation<Request, Result>
    }
}
