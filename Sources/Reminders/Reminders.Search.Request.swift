
extension Reminders.Search {
    public struct Request: Hashable, Sendable {
        public var query: Query
        public var limit: Int?

        public init(query: Query, limit: Int? = nil) {
            self.query = query
            self.limit = limit
        }
    }
}
