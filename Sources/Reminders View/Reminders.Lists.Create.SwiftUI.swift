public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Models
public import Reminder
public import Reminders
public import SwiftUI

extension Reminders.Lists.Create {
    // The sheet: `lists.create`'s request, composed and sent whole.
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Requesting<Reminders.Lists.Operations.Create>>

        public init(store: StoreOf<Requesting<Reminders.Lists.Operations.Create>>) {
            self.store = store
        }
    }
}

extension Reminders.Lists.Create.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        SwiftUI::Form {
            TextField("List Name", text: $store.request.list.title)
            if let error = store.sending.taskError {
                Section("Not saved") { Text(error.localizedDescription).foregroundStyle(.red) }
            }
        }
        .navigationTitle("New List")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { store.send(.cancelButtonTapped) }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { store.send(.sendButtonTapped) }
                    .disabled(store.request.list.isBlank || store.sending.isRunning)
            }
        }
    }
}
