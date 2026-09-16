extension Reminders.Overview {
    public struct Client: Sendable {
        public var fetch: @Sendable (Request) throws -> Contents

        public init(fetch: @escaping @Sendable (Request) throws -> Contents) {
            self.fetch = fetch
        }
    }
}
