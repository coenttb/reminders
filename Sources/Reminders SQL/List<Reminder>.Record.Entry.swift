public import Models
public import Reminder
public import StructuredQueries

extension Models.List<Reminder>.Record {
    @Selection
    public struct Entry: Hashable, Sendable {
        public let list: Models.List<Reminder>.Record
        public let count: Int

        public init(list: Models.List<Reminder>.Record, count: Int) {
            self.list = list
            self.count = count
        }
    }
}
