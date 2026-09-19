public import ComposableArchitecture2
import Interface_ComposableArchitecture
import List
import Operation
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI
import Tagged

extension Reminders.Read.Page {
    @View(Reminders.Read.Page.self)
    public struct SwiftUI {
        private var title: String
    }
}

extension Reminders.Read.Page.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        SwiftUI::List {
            EditingRows(store) { reminder in
                Reminder.Row.SwiftUI(
                    reminder: reminder,
                    complete: { store.update.complete(reminder.id, !reminder.completed) },
                    delete: { store.delete(reminder.id) },
                    edit: { store.editing = .init(reminder) }
                )
            } editor: { editor in
                Reminders.Update.SwiftUI(store: editor)
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
