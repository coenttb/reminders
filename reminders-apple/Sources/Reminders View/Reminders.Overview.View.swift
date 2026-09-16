public import Foundation
public import Organizing
public import Reminders
public import Reminders_Interface
public import SwiftUI
public import Tagged

extension Reminders.Overview {
    public struct View {
        private var overview: Reminders.Overview
        private var now: Date
        private var calendar: Calendar
        private var open: (Reminders.Filter) -> Void
        private var details: (Organizing.List<Reminder>.ID) -> Void
        private var delete: (Organizing.List<Reminder>.ID) -> Void
        private var move: (IndexSet, Int) -> Void
        private var deleteTag: (Tag<Reminder>.ID) -> Void
        @Environment(\.editMode) private var editMode

        public init(
            _ overview: Reminders.Overview,
            now: Date,
            calendar: Calendar,
            open: @escaping (Reminders.Filter) -> Void,
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

extension Reminders.Overview.View: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let counts = overview.counts
        Section {
            if editMode?.wrappedValue.isEditing == true {
                ForEach(Reminders.Filter.smart(flagged: counts.flagged > 0), id: \.self) { filter in
                    HStack(spacing: 16) {
                        Reminders.Filter.Tile.badge(for: filter, day: calendar.component(.day, from: now))
                        Text(filter.title ?? "")
                    }
                }
                .onMove { _, _ in }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    Reminders.Filter.Tile(.today, glyph: .today(day: calendar.component(.day, from: now)), fill: .today, count: counts.today, open: open)
                    Reminders.Filter.Tile(.scheduled, glyph: .symbol("calendar"), fill: .scheduled, count: counts.scheduled, open: open)
                    Reminders.Filter.Tile(.all, glyph: .symbol("tray.fill"), fill: .all, count: counts.all, open: open)
                    if counts.flagged > 0 {
                        Reminders.Filter.Tile(.flagged, glyph: .symbol("flag.fill"), fill: .flagged, count: counts.flagged, open: open)
                    }
                    Reminders.Filter.Tile(.completed, glyph: .symbol("checkmark"), fill: .completed, count: nil, open: open)
                }
                .buttonStyle(.plain)
                .listRowBackground(SwiftUI.Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
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
                Tag<Reminder>.Cloud(overview.usedTags, open: { open(.tags(Set($0))) }, delete: deleteTag)
            } header: {
                header("Tags")
            }
        }
    }

    private func header(_ title: String) -> some SwiftUI.View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(SwiftUI.Color.primary)
            .textCase(nil)
            .padding(.leading, -4)
    }
}
