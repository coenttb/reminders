extension Reminders.Search {
    public struct Client: Sendable {
        public var search: @Sendable (Request) async throws -> Contents

        public init(search: @escaping @Sendable (Request) async throws -> Contents) {
            self.search = search
        }
    }
}
