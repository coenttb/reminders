extension Reminders {
    public struct Editor: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Editor {
    public struct Client: Sendable {
        public var find: Find.Client
        public var start: Start.Client
        public var add: Add.Client
        public var update: Update.Client
        public var toggle: Toggle.Client
        public var delete: Delete.Client
        public var move: Move.Client
        public var deleteCompleted: DeleteCompleted.Client

        public init(
            find: Find.Client,
            start: Start.Client,
            add: Add.Client,
            update: Update.Client,
            toggle: Toggle.Client,
            delete: Delete.Client,
            move: Move.Client,
            deleteCompleted: DeleteCompleted.Client
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
