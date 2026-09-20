public import ComposableArchitecture2
import Interface_ComposableArchitecture
import List
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI

extension Reminders.Read {
    // The front screen's lists: the observed summary, with the intents that act on lists as a whole.
    @View(Reminders.self)
    public struct View {

        public var body: some SwiftUI::View {
            Section("My Lists") {
                ForEach(store.read.lists ?? []) { entry in
                    Button { store.read.page = .init(.list(entry.id)) } label: {
                        HStack {
                            Text(entry.list.title)
                            Spacer()
                            Text("\(entry.count)").foregroundStyle(.secondary).monospacedDigit()
                            Image(systemName: "chevron.forward").foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) { store.lists.delete(entry.id) }
                    }
                }
            }
        }
    }
}
