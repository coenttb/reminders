public import Reminders

extension Reminders.Sample {
    public struct Scale: Hashable, Sendable {
        public var lists: Int
        public var remindersPerList: Int
        public var tags: Int

        public init(lists: Int, remindersPerList: Int, tags: Int) {
            self.lists = lists
            self.remindersPerList = remindersPerList
            self.tags = tags
        }
    }
}

extension Reminders.Sample.Scale {
    public static let medium = Reminders.Sample.Scale(lists: 10, remindersPerList: 100, tags: 30)
    public static let large = Reminders.Sample.Scale(lists: 30, remindersPerList: 500, tags: 100)
    public static let extreme = Reminders.Sample.Scale(lists: 100, remindersPerList: 1_000, tags: 200)

    public var reminders: Int { lists * remindersPerList }
}
