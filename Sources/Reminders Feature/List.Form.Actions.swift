public import Models

extension Models.List.Form {
    public struct Actions {
        public var save: () -> Void
        public var cancel: () -> Void

        public init(save: @escaping () -> Void, cancel: @escaping () -> Void) {
            self.save = save
            self.cancel = cancel
        }
    }
}
