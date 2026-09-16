public import Reminders

extension Reminders.Search {
    public struct Request: Hashable, Sendable {
        public var search: Reminders.Search
        public var limit: Int?

        public init(search: Reminders.Search, limit: Int? = nil) {
            self.search = search
            self.limit = limit
        }
    }
}
