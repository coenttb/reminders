public import Foundation
public import Reminders
public import SwiftUI

extension Lists {
    /// The home sections inside the app's list: the smart-group grid, the user's
    /// lists, and the tags in use. Every tap is a callback; the value is read-only.
    public struct View: SwiftUI.View {
        private var lists: Lists
        private var now: Date
        private var open: (Lists.Detail) -> Void
        private var details: (Reminder.List.ID) -> Void
        private var delete: (Reminder.List.ID) -> Void
        private var move: (IndexSet, Int) -> Void
        private var deleteTag: (Tag.ID) -> Void

        public init(
            lists: Lists,
            now: Date,
            open: @escaping (Lists.Detail) -> Void,
            details: @escaping (Reminder.List.ID) -> Void,
            delete: @escaping (Reminder.List.ID) -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            deleteTag: @escaping (Tag.ID) -> Void
        ) {
            self.lists = lists
            self.now = now
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
        let stats = lists.stats(at: now)
        Section {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    Lists.Stats.Cell("Today", systemImage: "calendar.circle.fill", color: .blue, count: stats.today) { open(.today) }
                    Lists.Stats.Cell("Scheduled", systemImage: "calendar.circle.fill", color: .red, count: stats.scheduled) { open(.scheduled) }
                }
                GridRow {
                    Lists.Stats.Cell("All", systemImage: "tray.circle.fill", color: .gray, count: stats.all) { open(.all) }
                    Lists.Stats.Cell("Flagged", systemImage: "flag.circle.fill", color: .orange, count: stats.flagged) { open(.flagged) }
                }
                GridRow {
                    Lists.Stats.Cell("Completed", systemImage: "checkmark.circle.fill", color: .gray, count: nil) { open(.completed) }
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .padding(.horizontal, -20)
        }
        Section {
            ForEach(lists.orderedLists) { list in
                Button { open(.list(list.id)) } label: {
                    Reminder.List.Row(list, count: lists.count(in: list.id), details: { details(list.id) }, delete: { delete(list.id) })
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
            }
            .onMove(perform: move)
        } header: {
            header("My Lists")
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        Section {
            ForEach(lists.usedTags) { tag in
                Button { open(.tags([tag.id])) } label: { Tag.Row(tag) }.foregroundStyle(.primary)
            }
            .onDelete { offsets in
                for offset in offsets { deleteTag(lists.usedTags[offset].id) }
            }
        } header: {
            header("Tags")
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
    }

    private func header(_ title: String) -> some SwiftUI.View {
        Text(title)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(.primary)
            .textCase(nil)
            .padding(.top, -16)
            .padding(.horizontal, 4)
    }
}
