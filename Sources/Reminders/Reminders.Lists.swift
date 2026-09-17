extension Reminders {
    public struct Lists: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Lists {
    public struct Client: Sendable {
        public var add: Add.Client
        public var update: Update.Client
        public var delete: Delete.Client
        public var reorder: Reorder.Client

        public init(
            add: Add.Client,
            update: Update.Client,
            delete: Delete.Client,
            reorder: Reorder.Client
        ) {
            self.add = add
            self.update = update
            self.delete = delete
            self.reorder = reorder
        }
    }
}
