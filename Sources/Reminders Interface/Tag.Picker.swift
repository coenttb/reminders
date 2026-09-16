public import Organizing

extension Tag {
    /// The sheet that picks, adds, renames, and deletes tags, as the screen describes it. Its
    /// renderer holds the selection and the tags to pick from.
    public struct Picker {
        public var actions: Actions

        public init(actions: Actions) {
            self.actions = actions
        }
    }
}
