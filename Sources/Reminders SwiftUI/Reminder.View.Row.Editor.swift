import Interface_ComposableArchitecture
public import Reminder
public import SwiftUI

extension Reminder.View.Row {
    @View
    public struct Editor {
        @Binding private var draft: Reminder.Draft
        private var submit: () -> Void

        public var body: some SwiftUI::View {
            HStack(spacing: 12) {
                Reminder.View.Completion(
                    completed: draft.completed,
                    title: draft.title,
                    toggle: { draft.completed.toggle() }
                )
                TextField("New Reminder", text: $draft.title)
                    .textFieldStyle(.plain)
                    .focusOnPresentation()
                    .onSubmit(submit)
            }
        }
    }
}
