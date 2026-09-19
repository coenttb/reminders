public import ComposableArchitecture2
import Interface_ComposableArchitecture
import List
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Lists.Create {
    // The sheet: `lists.create`'s request, composed and sent whole.
    @View(Reminders.Lists.Create.self)
    public struct View: SwiftUI::View {

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
}
