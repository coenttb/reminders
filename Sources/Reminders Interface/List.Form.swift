public import Models

extension Models.List {
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
