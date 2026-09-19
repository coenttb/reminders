import Interface_ComposableArchitecture
public import Reminder
public import SwiftUI

extension Reminder {
    @View
    public struct View: SwiftUI::View {
        private var reminder: Reminder
        private var complete: () -> Void
        private var delete: () -> Void
        private var edit: () -> Void

        public var body: some SwiftUI::View {
            HStack(spacing: 12) {
                Button(action: complete) {
                    Image(systemName: reminder.completed ? "circle.inset.filled" : "circle")
                        .foregroundStyle(reminder.completed ? SwiftUI::Color.accentColor : SwiftUI::Color.secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(reminder.completed ? "Mark incomplete" : "Mark complete")
                .accessibilityValue(reminder.title)
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
