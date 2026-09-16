public import Organizing

extension Organizing.List {
    public struct Row {
        public var count: Int
        public var actions: Actions

        public init(count: Int, actions: Actions) {
            self.count = count
            self.actions = actions
        }
    }
}
