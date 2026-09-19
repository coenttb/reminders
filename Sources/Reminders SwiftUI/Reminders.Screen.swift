public import ComposableArchitecture2
import Interface_ComposableArchitecture
import List
import Operation
import Reminder
public import Reminders
public import Reminders_Feature
import Standard_Library_Extensions
public import SwiftUI

extension Reminders {
    // The universal screen tree: the front list, the pushed page, the presented sheet. A platform-specific
    // app composes the same views under its own tree beside this one.
    public struct Screen {
        @Bindable private var store: StoreOf<Reminders>

        public init(store: StoreOf<Reminders>) {
            self.store = store
        }
    }
}

extension Reminders.Screen: SwiftUI::View {
    public var body: some SwiftUI::View {
        @Bindable var read = store.read
        @Bindable var lists = store.lists
        NavigationStack {
            SwiftUI::List {
                Reminders.Read.SwiftUI(store: store)
                if let error = store.lists.writes.taskError ?? store.writes.taskError {
                    Text(error.localizedDescription).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add List", systemImage: "plus") { store.lists.create = .init(List<Reminder>.Draft()) }
                }
            }
            .navigationDestination(item: $read.scope(\.page)) { page in
                Reminders.Read.Page.SwiftUI(store: page, title: page.list.flatMap { store.read.lists?.first(id: $0) }?.list.title ?? "All")
            }
        }
        .sheet(item: $lists.scope(\.create)) { form in
            NavigationStack { Reminders.Lists.Create.SwiftUI(store: form) }
        }
    }
}
