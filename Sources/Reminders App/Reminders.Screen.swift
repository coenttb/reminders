public import ComposableArchitecture2
import Models
import Reminder
public import Reminders
public import Reminders_Feature
import Reminders_View
public import SwiftUI

extension Reminders {
    // The one screen tree: the front list, the pushed listing, the presented sheet, the failure alert.
    public struct Screen {
        @Bindable private var store: StoreOf<Reminders.Feature>

        public init(store: StoreOf<Reminders.Feature>) {
            self.store = store
        }
    }
}

extension Reminders.Screen: SwiftUI::View {
    public var body: some SwiftUI::View {
        NavigationStack {
            SwiftUI::List {
                Reminders.Read.SwiftUI(store: store.scope(\.overview))
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add List", systemImage: "plus") { store.send(.addListButtonTapped) }
                }
            }
            .navigationDestination(item: $store.scope(\.listing)) { listing in
                Reminders.Listing.SwiftUI(store: listing, title: store.overview.summary.lists.first { .list($0.id) == listing.filter }?.list.title ?? "All")
            }
        }
        .sheet(item: $store.scope(\.destination).list) { form in
            NavigationStack { Models.List<Reminder>.Form.SwiftUI(store: form) }
        }
        .alert("Something went wrong", isPresented: $store.failure.isPresent) {
            Button("OK") {}
        } message: {
            Text(store.failure ?? "")
        }
    }
}

// As in the TCA26 case studies: an optional drives the alert through a settable key path.
extension String? {
    fileprivate var isPresent: Bool {
        get { self != nil }
        set { if !newValue { self = nil } }
    }
}
