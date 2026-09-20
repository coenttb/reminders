import Optic
public import ComposableArchitecture2
import Interface_ComposableArchitecture
import List
import Reminder
public import Reminders
public import Reminders_Feature
import Standard_Library_Extensions
public import SwiftUI

extension Reminders {
    // The universal screen tree: the front list, the pushed page, the presented sheet. A platform-specific
    // app composes the same views under its own tree beside this one.
    @View(Reminders.self)
    public struct View {

        public var body: some SwiftUI::View {
            NavigationStack {
                SwiftUI::List {
                    Reminders.Read.View(store: store)
                    TaskFailure(store.lists.writes, store.writes).font(.footnote)
                }
                .navigationTitle("Reminders")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add List", systemImage: "plus") { store.lists.create = .init() }
                    }
                }
                .navigationDestination(item: $store.read.page) { page in
                    Reminders.Read.Page.View(
                        store: page,
                        title: page.list.flatMap {
                            store.read.lists?.first(id: $0)
                        }?.list.title ?? "All")
                }
            }
            .sheet(item: $store.lists.create) { form in
                NavigationStack { Reminders.Lists.Create.View(store: form) }
            }
        }
    }
}
