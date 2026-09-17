public import Models
public import Reminder

extension Reminders.Lists {
    public enum Delete {
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>
    }
}

extension Reminders.Lists.Delete {
    public struct Request: Hashable, Sendable {
        public var id: List<Reminder>.ID
        public var replacement: List<Reminder>.ID

        public init(id: List<Reminder>.ID, replacement: List<Reminder>.ID) {
            self.id = id
            self.replacement = replacement
        }
    }
}
