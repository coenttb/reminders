import Interface_ComposableArchitecture
public import Reminder
public import SwiftUI

extension Reminder.View {
    @View
    public struct Row {
        private var reminder: Reminder
        private var complete: () -> Void
        private var delete: () -> Void
        private var edit: () -> Void

        public var body: some SwiftUI::View {
            HStack(spacing: 12) {
                Completion(completed: reminder.completed, title: reminder.title, toggle: complete)

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
}
