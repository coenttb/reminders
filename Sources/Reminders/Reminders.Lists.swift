extension Reminders {
    public struct Lists: Sendable {
        public var create: Create
        public var update: Update
        public var delete: Delete
        public var reorder: Reorder

        public init(
            create: Create,
            update: Update,
            delete: Delete,
            reorder: Reorder
        ) {
            self.create = create
            self.update = update
            self.delete = delete
            self.reorder = reorder
        }
    }
}
