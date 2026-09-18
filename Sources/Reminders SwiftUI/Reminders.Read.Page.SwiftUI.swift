public import ComposableArchitecture2
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
        // The editor is the only text field on the page: focus is on it or nowhere.
        @FocusState private var focus: Bool

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
            ForEach(store.rows) { reminder in
                // The editor is one view that moves between rows; every other row is a plain value.
                if reminder.id == editing, let editor = store.scope(\.editing, action: \.self) {
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
            // A new row is a draft until its editor leaves.
            if store.editing?.original == nil, let editor = store.scope(\.editing, action: \.self) {
                Reminders.Update.SwiftUI(store: editor, focus: $focus)
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
        .onChange(of: store.editing == nil) { _, ended in focus = !ended }
        .toolbar {
            if store.editing != nil {
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
    private func startNewReminder() {
        guard let list = store.list else { return }
        store.editing = .init(Reminder.Draft(list: list))
    }
}
