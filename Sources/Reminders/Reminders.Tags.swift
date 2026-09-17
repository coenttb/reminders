extension Reminders {
    public struct Tags: Sendable {
        public var create: Create
        public var update: Update
        public var delete: Delete
        public var list: List

        public init(
            create: Create,
            update: Update,
            delete: Delete,
            list: List
        ) {
            self.create = create
            self.update = update
            self.delete = delete
            self.list = list
        }
    }
}
