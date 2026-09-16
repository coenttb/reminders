import Organizing
import Reminder
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SwiftUI
import Tagged

extension Reminders.Overview.View {
    public struct SwiftUI {
        private var contents: Reminders.Overview.Contents
        private var view: Reminders.Overview.View
        @Environment(\.editMode) private var editMode

        public init(contents: Reminders.Overview.Contents, view: Reminders.Overview.View) {
            self.contents = contents
            self.view = view
        }
    }
}

extension Reminders.Overview.View.SwiftUI: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let counts = contents.counts
        let day = view.calendar.component(.day, from: view.now)
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
                        Reminders.Filter.Tile.SwiftUI(
                            tile: Reminders.Filter.Tile(filter: filter, count: counts[filter], open: view.actions.open),
                            style: Reminders.Filter.Style(filter, list: nil, day: day)
                        )
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(SwiftUI::Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .listSectionMargins(.top, 0)
        Section {
            ForEach(contents.lists) { entry in
                Button { view.actions.open(.list(entry.id)) } label: {
                    Organizing.List<Reminder>.Row.SwiftUI(
                        list: entry.list,
                        row: Organizing.List<Reminder>.Row(
                            count: entry.count,
                            actions: Organizing.List<Reminder>.Row.Actions(details: { view.actions.details(entry.id) }, delete: { view.actions.delete(entry.id) })
                        )
                    )
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
            }
            .onMove(perform: view.actions.move)
            .onDelete { offsets in
                for offset in offsets { view.actions.delete(contents.lists[offset].id) }
            }
        } header: {
            header("My Lists")
        }
        let usedTags = contents.usedTags
        if !usedTags.isEmpty {
            Section {
                Tag<Reminder>.Cloud.SwiftUI(
                    tags: usedTags,
                    cloud: Tag<Reminder>.Cloud(actions: Tag<Reminder>.Cloud.Actions(open: { view.actions.open(.tags(Set($0))) }, delete: view.actions.deleteTag))
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
