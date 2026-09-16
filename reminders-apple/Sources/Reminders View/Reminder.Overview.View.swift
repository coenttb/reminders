public import Foundation
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
        private var now: Date
        private var calendar: Calendar
        private var open: (Reminder.Filter) -> Void
        private var details: (Organizing.List<Reminder>.ID) -> Void
        private var delete: (Organizing.List<Reminder>.ID) -> Void
        private var move: (IndexSet, Int) -> Void
        private var deleteTag: (Tag<Reminder>.ID) -> Void
        @Environment(\.editMode) private var editMode

        public init(
            _ overview: Reminder.Overview,
            now: Date,
            calendar: Calendar,
            open: @escaping (Reminder.Filter) -> Void,
            details: @escaping (Organizing.List<Reminder>.ID) -> Void,
            delete: @escaping (Organizing.List<Reminder>.ID) -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            deleteTag: @escaping (Tag<Reminder>.ID) -> Void
        ) {
            self.overview = overview
            self.now = now
            self.calendar = calendar
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
            if editMode?.wrappedValue.isEditing == true {
                // Edit mode lists the smart groups as rows with grips, as stock does
                // (Evidence/Parity/edit-mode); stock's visibility toggles are not modelled.
                ForEach(Reminder.Filter.smart(flagged: counts.flagged > 0), id: \.self) { filter in
                    HStack(spacing: 16) {
                        Reminder.Filter.Tile.badge(for: filter, day: calendar.component(.day, from: now))
                        Text(filter.title ?? "")
                    }
                }
                .onMove { _, _ in }
            } else {
                // Flagged appears only while something is flagged, as in iOS 27.
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    Reminder.Filter.Tile(.today, glyph: .today(day: calendar.component(.day, from: now)), fill: .today, count: counts.today, open: open)
                    Reminder.Filter.Tile(.scheduled, glyph: .symbol("calendar"), fill: .scheduled, count: counts.scheduled, open: open)
                    Reminder.Filter.Tile(.all, glyph: .symbol("tray.fill"), fill: .all, count: counts.all, open: open)
                    if counts.flagged > 0 {
                        Reminder.Filter.Tile(.flagged, glyph: .symbol("flag.fill"), fill: .flagged, count: counts.flagged, open: open)
                    }
                    Reminder.Filter.Tile(.completed, glyph: .symbol("checkmark"), fill: .completed, count: nil, open: open)
                }
                .buttonStyle(.plain)
                .listRowBackground(SwiftUI.Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        // The grid sits 16 pt under the bar, where the stock app puts it, not at the
        // inset-grouped default.
        .listSectionMargins(.top, 0)
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
                Tag<Reminder>.Cloud(overview.usedTags, open: { open(.tags($0)) }, delete: deleteTag)
            } header: {
                header("Tags")
            }
        }
    }

    private func header(_ title: String) -> some SwiftUI.View {
        // `.primary` inside a header resolves against the header's secondary style;
        // the color itself keeps the stock black.
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(SwiftUI.Color.primary)
            .textCase(nil)
            .padding(.leading, -4)
    }
}
