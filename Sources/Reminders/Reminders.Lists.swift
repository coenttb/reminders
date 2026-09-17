extension Reminders {
    public struct Lists: Sendable {
        public var add: Add
        public var update: Update
        public var delete: Delete
        public var reorder: Reorder

        public init(
            add: Add,
            update: Update,
            delete: Delete,
            reorder: Reorder
        ) {
            self.add = add
            self.update = update
            self.delete = delete
            self.reorder = reorder
        }
    }
}
