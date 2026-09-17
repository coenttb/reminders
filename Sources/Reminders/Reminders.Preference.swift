public import Foundation

extension Reminders {
    public struct Preference: Hashable, Sendable {
        public var ordering: Ordering
        public var direction: SortOrder
        public var showCompleted: Bool

        public init(ordering: Ordering, direction: SortOrder = .forward, showCompleted: Bool) {
            self.ordering = ordering
            self.direction = direction
            self.showCompleted = showCompleted
        }
    }
}
