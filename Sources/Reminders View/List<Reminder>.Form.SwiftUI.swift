public import ComposableArchitecture2
public import Models
public import Reminder
public import Reminders_Feature
public import SwiftUI

extension Models.List<Reminder>.Form {
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Models.List<Reminder>.Form.Feature>

        public init(store: StoreOf<Models.List<Reminder>.Form.Feature>) {
            self.store = store
        }
    }
}

extension Models.List<Reminder>.Form.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        SwiftUI::Form {
            TextField("List Name", text: $store.draft.title)
            if let failure = store.failure {
                Section("Not saved") { Text(failure).foregroundStyle(.red) }
            }
        }
        .navigationTitle("New List")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { store.send(.cancelButtonTapped) }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { store.send(.saveButtonTapped) }.disabled(store.draft.isBlank)
            }
        }
    }
}
