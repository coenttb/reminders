public import Organizing
public import Reminders
public import Reminders_Application
public import SwiftUI
public import Tagged

extension Reminder.Overview {
    /// The home sections inside the app's list: the smart-group tiles, the user's
    /// lists, and the tags in use. Every tap is a callback; the value is read-only.
    public struct View: SwiftUI.View {
        private var overview: Reminder.Overview
        private var open: (Reminder.Filter) -> Void
        private var details: (Organizing.List<Reminder>.ID) -> Void
        private var delete: (Organizing.List<Reminder>.ID) -> Void
        private var move: (IndexSet, Int) -> Void
        private var deleteTag: (Tag<Reminder>.ID) -> Void

        public init(
            _ overview: Reminder.Overview,
            open: @escaping (Reminder.Filter) -> Void,
            details: @escaping (Organizing.List<Reminder>.ID) -> Void,
            delete: @escaping (Organizing.List<Reminder>.ID) -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            deleteTag: @escaping (Tag<Reminder>.ID) -> Void
        ) {
            self.overview = overview
            self.open = open
            self.details = details
            self.delete = delete
            self.move = move
            self.deleteTag = deleteTag
        }
    }
}

extension Reminder.Overview.View {
    @ViewBuilder public var body: some SwiftUI.View {
        let counts = overview.counts
        Section {
            // Flagged appears only while something is flagged, as in iOS 27.
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                Reminder.Filter.Tile(.today, systemImage: "calendar", color: .blue, count: counts.today, open: open)
                Reminder.Filter.Tile(.scheduled, systemImage: "calendar.badge.clock", color: .red, count: counts.scheduled, open: open)
                Reminder.Filter.Tile(.all, systemImage: "tray.fill", color: SwiftUI.Color(.darkGray), count: counts.all, open: open)
                if counts.flagged > 0 {
                    Reminder.Filter.Tile(.flagged, systemImage: "flag.fill", color: .orange, count: counts.flagged, open: open)
                }
                Reminder.Filter.Tile(.completed, systemImage: "checkmark", color: .gray, count: nil, open: open)
            }
            .buttonStyle(.plain)
            .listRowBackground(SwiftUI.Color.clear)
            .listRowInsets(EdgeInsets())
        }
        Section {
            ForEach(overview.lists) { entry in
                Button { open(.list(entry.id)) } label: {
                    Organizing.List<Reminder>.Row(entry.list, count: entry.count, details: { details(entry.id) }, delete: { delete(entry.id) })
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
            }
            .onMove(perform: move)
            .onDelete { offsets in
                for offset in offsets { delete(overview.lists[offset].id) }
            }
        } header: {
            header("My Lists")
        }
        if !overview.usedTags.isEmpty {
            Section {
                ForEach(overview.usedTags) { tag in
                    Button { open(.tags([tag.id])) } label: { Tag<Reminder>.Row(tag) }.foregroundStyle(.primary)
                }
                .onDelete { offsets in
                    for offset in offsets { deleteTag(overview.usedTags[offset].id) }
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
