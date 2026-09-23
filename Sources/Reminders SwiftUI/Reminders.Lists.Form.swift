public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import List
public import Operation
public import Reminder
public import Reminders
public import SwiftUI

extension Reminders.Lists {
    public struct Form<Symbol: Operation::Operation.Composed>: SwiftUI::View
    where Symbol.Input: Copyable & Escapable, Symbol.Call: Copyable {
        @Stored<Requesting<Symbol>> private var store: StoreOf<Requesting<Symbol>>
        private let draft: WritableKeyPath<Requesting<Symbol>.State, List::List<Reminder>.Draft>
        private let title: Text

        public init(
            store: StoreOf<Requesting<Symbol>>,
            draft: WritableKeyPath<Requesting<Symbol>.State, List::List<Reminder>.Draft>,
            title: Text
        ) {
            _store = Stored(wrappedValue: store)
            self.draft = draft
            self.title = title
        }

        public var body: some SwiftUI::View {
            SwiftUI::Form {
                TextField("List Name", text: $store[dynamicMember: draft].title)
                Tasks.Failure("Not saved", store.sending)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Submit("Done", store: store, allowing: !store.state[keyPath: draft].isBlank)
                }
            }
        }
    }
}
