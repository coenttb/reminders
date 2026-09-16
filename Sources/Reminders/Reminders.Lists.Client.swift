public import Models
public import Reminder

extension Reminders.Lists {
    public struct Client: Sendable {
        public var add: @Sendable (List<Reminder>) throws -> Void
        public var update: @Sendable (List<Reminder>) throws -> Bool
        public var delete: @Sendable (List<Reminder>.ID, _ replacement: List<Reminder>.ID) throws -> Void
        public var reorder: @Sendable ([List<Reminder>.ID]) throws -> Void

        public init(
            add: @escaping @Sendable (List<Reminder>) throws -> Void,
            update: @escaping @Sendable (List<Reminder>) throws -> Bool,
            delete: @escaping @Sendable (List<Reminder>.ID, _ replacement: List<Reminder>.ID) throws -> Void,
            reorder: @escaping @Sendable ([List<Reminder>.ID]) throws -> Void
        ) {
            self.add = add
            self.update = update
            self.delete = delete
            self.reorder = reorder
        }
    }
}
