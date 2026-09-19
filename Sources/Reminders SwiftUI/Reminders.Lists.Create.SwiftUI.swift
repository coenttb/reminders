public import ComposableArchitecture2
import Interface_ComposableArchitecture
import List
import Operation
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Lists.Create {
    // The sheet: `lists.create`'s request, composed and sent whole.
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminders.Lists.Create>

        public init(store: StoreOf<Reminders.Lists.Create>) {
            self.store = store
        }
    }
}

extension Reminders.Lists.Create.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        SwiftUI::Form {
            TextField("List Name", text: $store.title)
            if let error = store.sending.taskError {
                Section("Not saved") { Text(error.localizedDescription).foregroundStyle(.red) }
            }
        }
        .navigationTitle("New List")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { store.dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { store.send() }
                    .disabled(store.isBlank || store.sending.isRunning)
            }
        }
    }
}
