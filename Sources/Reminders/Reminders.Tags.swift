extension Reminders {
    public struct Tags: Sendable {
        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Tags {
    public struct Client: Sendable {
        public var add: Add.Client
        public var rename: Rename.Client
        public var delete: Delete.Client
        public var suggest: Suggest.Client

        public init(
            add: Add.Client,
            rename: Rename.Client,
            delete: Delete.Client,
            suggest: Suggest.Client
        ) {
            self.add = add
            self.rename = rename
            self.delete = delete
            self.suggest = suggest
        }
    }
}
