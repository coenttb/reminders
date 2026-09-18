public import ComposableArchitecture2
import Models
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Read {
    public struct SwiftUI {
        private var store: StoreOf<Reminders.Read.Feature>

        public init(store: StoreOf<Reminders.Read.Feature>) {
            self.store = store
        }
    }
}

extension Reminders.Read.SwiftUI: SwiftUI::View {
    public var body: some SwiftUI::View {
        Section("My Lists") {
            ForEach(store.summary.lists) { entry in
                Button { store.send(.listTapped(entry.id)) } label: {
                    HStack {
                        Text(entry.list.title)
                        Spacer()
                        Text("\(entry.count)").foregroundStyle(.secondary).monospacedDigit()
                        Image(systemName: "chevron.forward").foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) { store.send(.listDeleted(entry.id)) }
                }
            }
        }
    }
}
