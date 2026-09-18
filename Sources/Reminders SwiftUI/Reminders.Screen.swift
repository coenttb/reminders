public import ComposableArchitecture2
import Dependencies
import Interface_ComposableArchitecture
import Models
import Reminder
public import Reminders
public import Reminders_Feature
import Standard_Library_Extensions
public import SwiftUI

extension Reminders {
    // The universal screen tree: the front list, the pushed page, the presented sheet. A platform-specific
    // app composes the same views under its own tree beside this one.
    public struct Screen {
        @Bindable private var store: StoreOf<Reminders.Feature>
        // A new list's identity is the caller's: the sheet opens on a list that already has one.
        @Dependency(\.uuid) private var uuid

        public init(store: StoreOf<Reminders.Feature>) {
            self.store = store
        }
    }
}

extension Reminders.Screen: SwiftUI::View {
    public var body: some SwiftUI::View {
        NavigationStack {
            SwiftUI::List {
                Reminders.Read.SwiftUI(store: store)
                if let error = store.writes.taskError {
                    Text(error.localizedDescription).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add List", systemImage: "plus") { store.destination = .init(Models.List(id: .init(uuid()))) }
                }
            }
            .navigationDestination(item: $store.scope(\.listing)) { listing in
                Reminders.Read.Page.SwiftUI(store: listing, title: listing.list.flatMap { store.overview.lists?.first(id: $0) }?.list.title ?? "All")
            }
        }
        .sheet(item: $store.scope(\.destination)) { form in
            NavigationStack { Reminders.Lists.Create.SwiftUI(store: form) }
        }
    }
}
