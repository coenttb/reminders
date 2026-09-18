public import ComposableArchitecture2
import Dependencies
import Models
import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI
import Tagged

extension Reminders.Read {
    public struct SwiftUI {
        private var store: StoreOf<Reminders.Read.Feature>
        @Dependency(\.date.now) private var now
        @Dependency(\.calendar) private var calendar
        @Environment(\.editMode) private var editMode

        public init(store: StoreOf<Reminders.Read.Feature>) {
            self.store = store
        }
    }
}

extension Reminders.Read.SwiftUI: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let contents = store.summary
        let counts = contents.counts
        let day = calendar.component(.day, from: now)
        Section {
            if editMode?.wrappedValue.isEditing == true {
                ForEach(Reminders.Filter.Style.smart(flagged: counts.flagged > 0), id: \.self) { filter in
                    HStack(spacing: 16) {
                        Reminders.Filter.Style.badge(for: filter, day: day)
                        Text(Reminders.Filter.Style(filter, list: nil, day: day).title ?? "")
                    }
                }
                .onMove { _, _ in }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(Reminders.Filter.Style.smart(flagged: counts.flagged > 0), id: \.self) { filter in
                        Reminders.Filter.Tile.SwiftUI(filter: filter, count: counts[filter], style: Reminders.Filter.Style(filter, list: nil, day: day)) {
                            store.send(.filterTapped(filter))
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(SwiftUI::Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        // The tiles sit 22 pt under the bar, as the stock tiles do.
        .listSectionMargins(.top, 6)
        Section {
            ForEach(contents.lists) { entry in
                Button { store.send(.listTapped(entry.id)) } label: {
                    Models.List<Reminder>.Row.SwiftUI(
                        list: entry.list,
                        count: entry.count,
                        details: { store.send(.listDetailsButtonTapped(entry.id)) },
                        delete: { store.send(.listDeleted(entry.id)) }
                    )
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
            }
            .onMove { store.send(.listsMoved($0, $1)) }
            .onDelete { offsets in
                for offset in offsets { store.send(.listDeleted(contents.lists[offset].id)) }
            }
            // Recently Deleted closes My Lists while it holds anything; it cannot be deleted, moved, or edited.
            if counts.deleted > 0 {
                Button { store.send(.filterTapped(.recentlyDeleted)) } label: {
                    HStack(spacing: 16) {
                        Reminders.Filter.Style.badge(for: .recentlyDeleted, day: day)
                        Text("Recently Deleted")
                        Spacer()
                        if editMode?.wrappedValue.isEditing != true {
                            HStack(spacing: 10) {
                                Text("\(counts.deleted)").foregroundStyle(.secondary).monospacedDigit()
                                Image(systemName: "chevron.forward").foregroundStyle(.tertiary).font(.body.weight(.semibold))
                            }
                        }
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
                .moveDisabled(true)
                .deleteDisabled(true)
            }
        } header: {
            header("My Lists")
        }
        let usedTags = contents.usedTags
        if !usedTags.isEmpty {
            Section {
                Tag<Reminder>.Cloud.SwiftUI(
                    tags: usedTags,
                    open: { store.send(.filterTapped(.tags(Set($0)))) },
                    delete: { store.send(.tagDeleted($0)) }
                )
            } header: {
                header("Tags")
            }
        }
    }

    private func header(_ title: String) -> some SwiftUI::View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(SwiftUI::Color.primary)
            .textCase(nil)
            .padding(.leading, -4)
    }
}
