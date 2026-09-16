public import Reminders
public import Models
public import Reminder
import Tagged

extension Reminders.Search.View {
    public struct Actions {
        public var rows: Reminder.Row.Actions
        public var addTag: (Tag<Reminder>) -> Void
        public var toggleCompleted: () -> Void
        public var endReached: () -> Void
        public var deleteCompleted: (Int?) -> Void

        public init(
            rows: Reminder.Row.Actions,
            addTag: @escaping (Tag<Reminder>) -> Void,
            toggleCompleted: @escaping () -> Void,
            endReached: @escaping () -> Void,
            deleteCompleted: @escaping (Int?) -> Void
        ) {
            self.rows = rows
            self.addTag = addTag
            self.toggleCompleted = toggleCompleted
            self.endReached = endReached
            self.deleteCompleted = deleteCompleted
        }
    }
}
