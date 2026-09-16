public import Models

extension Models.List.Row {
    public struct Actions {
        public var details: () -> Void
        public var delete: () -> Void

        public init(details: @escaping () -> Void, delete: @escaping () -> Void) {
            self.details = details
            self.delete = delete
        }
    }
}
