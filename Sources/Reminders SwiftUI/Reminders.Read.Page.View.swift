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
                EditingRows(
                    store,
                    row: { reminder in
                        Reminder.View(
                            reminder: reminder,
                            complete: { store.update.complete(reminder.id, !reminder.completed) },
                            delete: { store.delete(reminder.id) },
                            edit: { store.editing = .init(reminder) }
                        )
                    },
                    editor: Reminders.Update.View.init)
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

        private func startNewReminder() {
            guard let list = store.list else { return }
            store.editing = .init(Reminder.Draft(list: list))
        }
    }
}
