import Optic
public import ComposableArchitecture2
import Interface_ComposableArchitecture
import List
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Read.Page {
    @View(Reminders.Read.Page.self)
    public struct View {
        private var title: String

        public var body: some SwiftUI::View {
            SwiftUI::List {
                Editing.Rows(
                    store.rows,
                    editing: $store.editing,
                    insertion: .afterLast,
                    row: { reminder in
                        Reminder.View.Row(
                            reminder: reminder,
                            complete: { store.update.complete(reminder.id, !reminder.completed) },
                            delete: { store.delete(reminder.id) },
                            edit: { store.editing = .init(reminder) }
                        )
                    },
                    editor: Reminder.View.Row.Editor.init
                )
                Tasks.Failure(store.writes).font(.footnote)
            }
            .listStyle(.plain)
            .navigationTitle(title)
            .toolbar {
                if store.editing != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { store.editing = nil }
                    }
                } else {
                    #if os(iOS)
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        Button("New Reminder", systemImage: "plus", action: startNewReminder)
                            .labelStyle(.iconOnly)
                    }
                    #else
                    ToolbarItem(placement: .primaryAction) {
                        Button("New Reminder", systemImage: "plus", action: startNewReminder)
                    }
                    #endif
                }
            }
        }

        private func startNewReminder() {
            guard let list = store.list else { return }
            store.editing = .init(.init(list: list))
        }
    }
}
