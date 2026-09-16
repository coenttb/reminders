public import Organizing

extension Organizing.List {
    /// The sheet that edits one list, as the screen describes it. Its renderer holds the draft.
    public struct Form {
        public var isNew: Bool
        public var isDirty: Bool
        public var failure: String?
        public var actions: Actions

        public init(isNew: Bool, isDirty: Bool, failure: String?, actions: Actions) {
            self.isNew = isNew
            self.isDirty = isDirty
            self.failure = failure
            self.actions = actions
        }
    }
}
