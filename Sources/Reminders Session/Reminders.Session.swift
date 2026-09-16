public import Reminders

extension Reminders {
    public struct Session: Hashable, Sendable {
        public var filter: Filter?
        public var editing: Placement?

        public init(filter: Filter? = nil, editing: Placement? = nil) {
            self.filter = filter
            self.editing = editing
        }
    }
}
