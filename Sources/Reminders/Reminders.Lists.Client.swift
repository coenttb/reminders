public import Models
public import Reminder
public import Tagged

extension Reminders.Lists {
    public struct Client: Sendable {
        public var save: @Sendable (List<Reminder>, _ isNew: Bool) async throws -> Bool
        public var delete: @Sendable (List<Reminder>.ID, _ replacement: List<Reminder>.ID) async throws -> Void
        public var reorder: @Sendable ([List<Reminder>.ID]) async throws -> Void

        public init(
            save: @escaping @Sendable (List<Reminder>, _ isNew: Bool) async throws -> Bool,
            delete: @escaping @Sendable (List<Reminder>.ID, _ replacement: List<Reminder>.ID) async throws -> Void,
            reorder: @escaping @Sendable ([List<Reminder>.ID]) async throws -> Void
        ) {
            self.save = save
            self.delete = delete
            self.reorder = reorder
        }
    }
}
