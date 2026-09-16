public import Reminders

extension Reminders.Filter {
    /// One smart filter's tile on the home screen: the filter, its count, and what opens it.
    public struct Tile {
        public var filter: Reminders.Filter
        public var count: Int?
        public var open: (Reminders.Filter) -> Void

        public init(filter: Reminders.Filter, count: Int?, open: @escaping (Reminders.Filter) -> Void) {
            self.filter = filter
            self.count = count
            self.open = open
        }
    }
}
