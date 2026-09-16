public import Models
public import Reminder

extension Reminders.Tags {
    public struct Client: Sendable {
        public var add: @Sendable (_ title: String) async throws -> Tag<Reminder>?
        public var rename: @Sendable (Tag<Reminder>, _ title: String) async throws -> Tag<Reminder>?
        public var delete: @Sendable (Tag<Reminder>) async throws -> Void

        public init(
            add: @escaping @Sendable (_ title: String) async throws -> Tag<Reminder>?,
            rename: @escaping @Sendable (Tag<Reminder>, _ title: String) async throws -> Tag<Reminder>?,
            delete: @escaping @Sendable (Tag<Reminder>) async throws -> Void
        ) {
            self.add = add
            self.rename = rename
            self.delete = delete
        }
    }
}
