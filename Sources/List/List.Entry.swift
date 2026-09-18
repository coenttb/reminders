public import Tagged

extension List {
    // A list with the number of open reminders it holds.
    public struct Entry: Identifiable, Hashable, Sendable {
        public var list: List
        public var count: Int

        public var id: List.ID { list.id }

        public init(list: List, count: Int) {
            self.list = list
            self.count = count
        }
    }
}
