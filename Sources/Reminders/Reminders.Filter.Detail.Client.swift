public import Foundation
public import Reminder
public import Tagged

extension Reminders.Filter.Detail {
    public struct Client: Sendable {
        public var fetch: @Sendable (Request) async throws -> Contents?
        public var setOrdering: @Sendable (Reminders.Ordering, _ filter: Reminders.Filter) async throws -> Void
        public var toggleShowCompleted: @Sendable (_ filter: Reminders.Filter) async throws -> Void
        public var clearCompleted: @Sendable (_ filter: Reminders.Filter, _ today: Range<Date>) async throws -> Void
        public var move: @Sendable ([Reminder.ID], _ filter: Reminders.Filter) async throws -> Void

        public init(
            fetch: @escaping @Sendable (Request) async throws -> Contents?,
            setOrdering: @escaping @Sendable (Reminders.Ordering, _ filter: Reminders.Filter) async throws -> Void,
            toggleShowCompleted: @escaping @Sendable (_ filter: Reminders.Filter) async throws -> Void,
            clearCompleted: @escaping @Sendable (_ filter: Reminders.Filter, _ today: Range<Date>) async throws -> Void,
            move: @escaping @Sendable ([Reminder.ID], _ filter: Reminders.Filter) async throws -> Void
        ) {
            self.fetch = fetch
            self.setOrdering = setOrdering
            self.toggleShowCompleted = toggleShowCompleted
            self.clearCompleted = clearCompleted
            self.move = move
        }
    }
}
