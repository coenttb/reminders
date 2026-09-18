public import ComposableArchitecture2
import Models
import Reminder
public import Reminders
public import Reminders_Feature
import Reminders_View
public import SwiftUI

extension Reminders.Filter {
    // One open filter: the listing on its own store, with the lists the root already reads.
    public struct Screen {
        private var store: StoreOf<Reminders.Feature>
        private var listing: StoreOf<Reminders.Listing.Feature>

        public init(store: StoreOf<Reminders.Feature>, listing: StoreOf<Reminders.Listing.Feature>) {
            self.store = store
            self.listing = listing
        }
    }
}

extension Reminders.Filter.Screen: SwiftUI::View {
    public var body: some SwiftUI::View {
        Reminders.Listing.SwiftUI(store: listing, lists: store.overview.summary.lists.map(\.list) + store.overview.summary.trash)
    }
}
