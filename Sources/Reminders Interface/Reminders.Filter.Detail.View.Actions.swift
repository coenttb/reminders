public import Foundation
public import Reminders

extension Reminders.Filter.Detail.View {
    public struct Actions {
        public var rows: Reminder.Row.Actions
        public var editor: Reminder.Editor.Actions
        public var done: () -> Void
        public var backgroundTapped: () -> Void
        public var toggleCompleted: () -> Void
        public var endReached: () -> Void
        public var move: (IndexSet, Int) -> Void
        public var order: (Reminders.Ordering) -> Void
        public var newReminder: (() -> Void)?
        public var info: (() -> Void)?
        public var delete: (() -> Void)?
        public var clearCompleted: (() -> Void)?

        public init(
            rows: Reminder.Row.Actions,
            editor: Reminder.Editor.Actions,
            done: @escaping () -> Void,
            backgroundTapped: @escaping () -> Void,
            toggleCompleted: @escaping () -> Void,
            endReached: @escaping () -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            order: @escaping (Reminders.Ordering) -> Void,
            newReminder: (() -> Void)? = nil,
            info: (() -> Void)? = nil,
            delete: (() -> Void)? = nil,
            clearCompleted: (() -> Void)? = nil
        ) {
            self.rows = rows
            self.editor = editor
            self.done = done
            self.backgroundTapped = backgroundTapped
            self.toggleCompleted = toggleCompleted
            self.endReached = endReached
            self.move = move
            self.order = order
            self.newReminder = newReminder
            self.info = info
            self.delete = delete
            self.clearCompleted = clearCompleted
        }
    }
}
