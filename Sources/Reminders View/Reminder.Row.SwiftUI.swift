public import Reminder
public import SwiftUI

extension Reminder {
    public enum Row {}
}

extension Reminder.Row {
    public struct SwiftUI {
        private var reminder: Reminder
        private var complete: () -> Void
        private var delete: () -> Void
        private var edit: () -> Void

        public init(reminder: Reminder, complete: @escaping () -> Void, delete: @escaping () -> Void, edit: @escaping () -> Void) {
            self.reminder = reminder
            self.complete = complete
            self.delete = delete
            self.edit = edit
        }
    }
}

extension Reminder.Row.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        HStack(spacing: 12) {
            Button(action: complete) {
                Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                    .foregroundStyle(reminder.completed ? SwiftUI::Color.accentColor : SwiftUI::Color.secondary)
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            Button(action: edit) {
                Text(reminder.title)
                    .foregroundStyle(reminder.completed ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
        }
    }
}
