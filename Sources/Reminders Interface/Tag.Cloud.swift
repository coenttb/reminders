public import Organizing

extension Tag {
    /// The tags in use on the home screen and what they can do. Its renderer holds the records.
    public struct Cloud {
        public var actions: Actions

        public init(actions: Actions) {
            self.actions = actions
        }
    }
}
