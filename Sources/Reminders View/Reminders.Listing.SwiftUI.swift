public import ComposableArchitecture2
public import Models
public import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Listing {
    public struct SwiftUI {
        private var store: StoreOf<Reminders.Listing.Feature>
        private var title: String
        @FocusState private var focus: Reminder.ID?

        public init(store: StoreOf<Reminders.Listing.Feature>, title: String) {
            self.store = store
            self.title = title
        }
    }
}

extension Reminders.Listing.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        let editing = store.editing?.id
        SwiftUI::List {
            ForEach(store.contents.rows) { reminder in
                // The editor is one view that moves between rows; every other row is a plain value.
                if reminder.id == editing, let editor = store.scope(\.editing) {
                    Reminder.Editor.SwiftUI(store: editor, focus: $focus)
                } else {
                    Reminder.Row.SwiftUI(
                        reminder: reminder,
                        complete: { store.send(.reminderCompleteButtonTapped(reminder.id)) },
                        delete: { store.send(.reminderDeleted(reminder.id)) },
                        edit: { store.send(.reminderTapped(reminder.id)) }
                    )
                }
            }
            SwiftUI::Color.clear
                .frame(height: 200)
                .contentShape(.rect)
                .onTapGesture { store.send(.backgroundTapped) }
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .onChange(of: editing) { _, editing in focus = editing }
        .toolbar {
            if editing != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { store.send(.doneButtonTapped) }
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button("New Reminder", systemImage: "plus") { store.send(.newReminderButtonTapped) }
            }
        }
    }
}
