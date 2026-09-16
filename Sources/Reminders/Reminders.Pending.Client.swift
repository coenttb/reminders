public import Reminder
public import Tagged

extension Reminders.Pending {
    public struct Client: Sendable {
        public var fetch: @Sendable (Request) async throws -> Set<Reminder.ID>
        public var complete: @Sendable () async throws -> Void

        public init(
            fetch: @escaping @Sendable (Request) async throws -> Set<Reminder.ID>,
            complete: @escaping @Sendable () async throws -> Void
        ) {
            self.fetch = fetch
            self.complete = complete
        }
    }
}
