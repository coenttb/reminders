
extension Reminders.Filter {
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
