public import ComposableArchitecture2
public import Models
public import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Lists.Create {
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminders.Lists.Create.Feature>

        public init(store: StoreOf<Reminders.Lists.Create.Feature>) {
            self.store = store
        }
    }
}

extension Reminders.Lists.Create.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        SwiftUI::Form {
            TextField("List Name", text: $store.list.title)
            if let error = store.saving.taskError {
                Section("Not saved") { Text(error.localizedDescription).foregroundStyle(.red) }
            }
        }
        .navigationTitle("New List")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { store.send(.cancelButtonTapped) }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { store.send(.saveButtonTapped) }
                    .disabled(store.list.isBlank || store.saving.isRunning)
            }
        }
    }
}
