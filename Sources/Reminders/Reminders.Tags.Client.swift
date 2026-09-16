extension Reminders.Tags {
    public struct Client: Sendable {
        public var add: Add
        public var rename: Rename
        public var delete: Delete
        public var suggest: Suggest

        public init(
            add: Add,
            rename: Rename,
            delete: Delete,
            suggest: Suggest
        ) {
            self.add = add
            self.rename = rename
            self.delete = delete
            self.suggest = suggest
        }
    }
}
