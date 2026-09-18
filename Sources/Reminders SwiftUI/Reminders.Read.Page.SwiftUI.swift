public import ComposableArchitecture2
import Dependencies
public import Models
public import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI
public import Tagged

extension Reminders.Read.Page {
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminders.Read.Page.Feature>
        private var title: String
        @FocusState private var focus: Reminder.ID?
        // A new row's identity and creation time are the caller's; the row is created before it is edited.
        @Dependency(\.uuid) private var uuid
        @Dependency(\.date.now) private var now

        public init(store: StoreOf<Reminders.Read.Page.Feature>, title: String) {
            self.store = store
            self.title = title
        }
    }
}

extension Reminders.Read.Page.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        let editing = store.editing?.id
        SwiftUI::List {
            ForEach(store.contents.rows) { reminder in
                // The editor is one view that moves between rows; every other row is a plain value.
                if reminder.id == editing, let editor = store.scope(\.editing) {
                    Reminders.Update.SwiftUI(store: editor, focus: $focus)
                } else {
                    Reminder.Row.SwiftUI(
                        reminder: reminder,
                        complete: { store.update.complete(reminder.id, !reminder.completed) },
                        delete: { store.delete(reminder.id) },
                        edit: { store.editing = .init(reminder) }
                    )
                }
            }
            if let error = store.writes.taskError {
                Text(error.localizedDescription).foregroundStyle(.red).font(.footnote)
            }
            SwiftUI::Color.clear
                .frame(height: 200)
                .contentShape(.rect)
                .onTapGesture { store.editing == nil ? startNewReminder() : (store.editing = nil) }
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .onChange(of: editing) { _, editing in focus = editing }
        .toolbar {
            if editing != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { store.editing = nil }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("New Reminder", systemImage: "plus") { startNewReminder() }
            }
        }
    }
}

extension Reminders.Read.Page.SwiftUI {
    // Insert, then edit: the row exists before its editor does, so the editor only ever updates.
    private func startNewReminder() {
        guard let list = store.list else { return }
        let reminder = Reminder(id: Reminder.ID(uuid()), list: list, created: now)
        store.create(reminder)
        store.editing = .init(reminder)
    }
}
