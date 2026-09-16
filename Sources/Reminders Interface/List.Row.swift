public import Organizing

extension Organizing.List {
    /// A list's row on the home screen: its open count and what it can do. Its renderer holds
    /// the record.
    public struct Row {
        public var count: Int
        public var actions: Actions

        public init(count: Int, actions: Actions) {
            self.count = count
            self.actions = actions
        }
    }
}
