public import Reminders
public import SwiftUI

extension Lists {
    /// The home sections inside the app's list: the smart-group tiles, the user's
    /// lists, and the tags in use. Every tap is a callback; the value is read-only.
    public struct View: SwiftUI.View {
        private var home: Lists.Home
        private var open: (Lists.Detail) -> Void
        private var details: (Reminder.List.ID) -> Void
        private var delete: (Reminder.List.ID) -> Void
        private var move: (IndexSet, Int) -> Void
        private var deleteTag: (Tag.ID) -> Void

        public init(
            home: Lists.Home,
            open: @escaping (Lists.Detail) -> Void,
            details: @escaping (Reminder.List.ID) -> Void,
            delete: @escaping (Reminder.List.ID) -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            deleteTag: @escaping (Tag.ID) -> Void
        ) {
            self.home = home
            self.open = open
            self.details = details
            self.delete = delete
            self.move = move
            self.deleteTag = deleteTag
        }
    }
}

extension Lists.View {
    @ViewBuilder public var body: some SwiftUI.View {
        let stats = home.stats
        Section {
            // Flagged appears only while something is flagged, as in iOS 27.
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                Lists.Stats.Cell("Today", systemImage: "calendar", color: .blue, count: stats.today) { open(.today) }
                Lists.Stats.Cell("Scheduled", systemImage: "calendar.badge.clock", color: .red, count: stats.scheduled) { open(.scheduled) }
                Lists.Stats.Cell("All", systemImage: "tray.fill", color: Color(.darkGray), count: stats.all) { open(.all) }
                if stats.flagged > 0 {
                    Lists.Stats.Cell("Flagged", systemImage: "flag.fill", color: .orange, count: stats.flagged) { open(.flagged) }
                }
                Lists.Stats.Cell("Completed", systemImage: "checkmark", color: .gray, count: nil) { open(.completed) }
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        Section {
            ForEach(home.lists) { entry in
                Button { open(.list(entry.id)) } label: {
                    Reminder.List.Row(entry.list, count: entry.count, details: { details(entry.id) }, delete: { delete(entry.id) })
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
            }
            .onMove(perform: move)
            .onDelete { offsets in
                for offset in offsets { delete(home.lists[offset].id) }
            }
        } header: {
            header("My Lists")
        }
        if !home.usedTags.isEmpty {
            Section {
                ForEach(home.usedTags) { tag in
                    Button { open(.tags([tag.id])) } label: { Tag.Row(tag) }.foregroundStyle(.primary)
                }
                .onDelete { offsets in
                    for offset in offsets { deleteTag(home.usedTags[offset].id) }
                }
            } header: {
                header("Tags")
            }
        }
    }

    private func header(_ title: String) -> some SwiftUI.View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
            .textCase(nil)
            .padding(.top, -4)
            .padding(.leading, -4)
    }
}
