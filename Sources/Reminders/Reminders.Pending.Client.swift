public import Tagged
public import Reminder

extension Reminders.Pending {
    public struct Client: Sendable {
        public var fetch: @Sendable (Request) async throws -> Set<Reminder.ID>

        public init(fetch: @escaping @Sendable (Request) async throws -> Set<Reminder.ID>) {
            self.fetch = fetch
        }
    }
}
