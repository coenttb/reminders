public import Organizing
public import Reminder
public import StructuredQueries

extension List<Reminder>.Record {
    @Selection
    public struct Entry: Hashable, Sendable {
        public let list: List<Reminder>.Record
        public let count: Int

        public init(list: List<Reminder>.Record, count: Int) {
            self.list = list
            self.count = count
        }
    }
}
