public import Models
public import Reminder
public import Tagged

extension Reminders.Tags {
    public struct Client: Sendable {
        public var add: @Sendable (_ title: String) async throws -> Tag<Reminder>.ID?
        public var rename: @Sendable (Tag<Reminder>.ID, _ title: String) async throws -> Tag<Reminder>.ID?
        public var delete: @Sendable (Tag<Reminder>.ID) async throws -> Void

        public init(
            add: @escaping @Sendable (_ title: String) async throws -> Tag<Reminder>.ID?,
            rename: @escaping @Sendable (Tag<Reminder>.ID, _ title: String) async throws -> Tag<Reminder>.ID?,
            delete: @escaping @Sendable (Tag<Reminder>.ID) async throws -> Void
        ) {
            self.add = add
            self.rename = rename
            self.delete = delete
        }
    }
}
