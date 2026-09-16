extension Reminders.Listing {
    public struct Client: Sendable {
        public var fetch: @Sendable (Request) throws -> Page

        public init(fetch: @escaping @Sendable (Request) throws -> Page) {
            self.fetch = fetch
        }
    }
}
