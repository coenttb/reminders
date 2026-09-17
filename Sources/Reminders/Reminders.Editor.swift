extension Reminders {
    public struct Editor: Sendable {
        public var find: Find
        public var start: Start
        public var add: Add
        public var update: Update
        public var toggle: Toggle
        public var delete: Delete
        public var move: Move
        public var deleteCompleted: DeleteCompleted

        public init(
            find: Find,
            start: Start,
            add: Add,
            update: Update,
            toggle: Toggle,
            delete: Delete,
            move: Move,
            deleteCompleted: DeleteCompleted
        ) {
            self.find = find
            self.start = start
            self.add = add
            self.update = update
            self.toggle = toggle
            self.delete = delete
            self.move = move
            self.deleteCompleted = deleteCompleted
        }
    }
}
