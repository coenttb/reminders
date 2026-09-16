extension Reminders.Overview {
    public struct Client: Sendable {
        public var fetch: @Sendable (Request) async throws -> Contents

        public init(fetch: @escaping @Sendable (Request) async throws -> Contents) {
            self.fetch = fetch
        }
    }
}
