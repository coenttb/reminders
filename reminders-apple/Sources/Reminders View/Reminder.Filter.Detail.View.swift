public import Foundation
public import Reminders
public import Reminders_Application
public import SwiftUI

extension Reminder.Filter.Detail {
    /// The pushed screen for one filter: its colored title, the reminders it
    /// shows with one of them possibly edited in place, the sort and
    /// show-completed menu, and New Reminder for a list. While a row is edited
    /// the menu gives way to Done and the plus hides, as in iOS 27.
    public struct View: SwiftUI.View {
        private var title: String
        private var detail: Reminder.Filter.Detail
        private var editing: Reminder.ID?
        private var now: Date
        private var calendar: Calendar
        private var draft: (Reminder.ID) -> Binding<Reminder>
        private var rows: Reminder.Row.Actions
        private var editor: Reminder.Editor.Actions
        private var done: () -> Void
        private var backgroundTapped: () -> Void
        private var move: (IndexSet, Int) -> Void
        private var order: (Reminder.Ordering) -> Void
        private var toggleCompleted: () -> Void
        private var newReminder: () -> Void
        @State private var titleVisible = false
        @State private var titleHeight: CGFloat = 36
        @FocusState private var focus: Reminder.Focus?

        public init(
            _ detail: Reminder.Filter.Detail,
            title: String,
            editing: Reminder.ID?,
            now: Date,
            calendar: Calendar,
            draft: @escaping (Reminder.ID) -> Binding<Reminder>,
            rows: Reminder.Row.Actions,
            editor: Reminder.Editor.Actions,
            done: @escaping () -> Void,
            backgroundTapped: @escaping () -> Void,
            move: @escaping (IndexSet, Int) -> Void,
            order: @escaping (Reminder.Ordering) -> Void,
            toggleCompleted: @escaping () -> Void,
            newReminder: @escaping () -> Void
        ) {
            self.detail = detail
            self.title = title
            self.editing = editing
            self.now = now
            self.calendar = calendar
            self.draft = draft
            self.rows = rows
            self.editor = editor
            self.done = done
            self.backgroundTapped = backgroundTapped
            self.move = move
            self.order = order
            self.toggleCompleted = toggleCompleted
            self.newReminder = newReminder
        }
    }
}

extension Reminder.Filter.Detail.View {
    @ViewBuilder public var body: some SwiftUI.View {
        let filter = detail.filter
        let color = filter.color(list: detail.color)
        let preference = detail.preference
        ScrollViewReader { proxy in
        SwiftUI.List {
            GeometryReader { proxy in
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(color)
                    .onAppear { titleHeight = proxy.size.height }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            ForEach(detail.rows) { row in
                if row.id == editing {
                    Reminder.Editor(reminder: draft(row.id), color: row.color.swiftUI, now: now, calendar: calendar, focus: $focus, actions: editor)
                } else {
                    Reminder.Row(row.reminder, color: row.color.swiftUI, now: now, calendar: calendar, actions: rowActions)
                }
            }
            .onMove(perform: move)
            // The empty part of a list: a tap there ends editing, or starts a new row.
            SwiftUI.Color.clear
                .frame(height: 320)
                .contentShape(.rect)
                .onTapGesture(perform: backgroundTapped)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                // Transparent, so the shadow of a card in the last row is not covered.
                .listRowBackground(SwiftUI.Color.clear)
        }
        .listStyle(.plain)
        // Rows animate when they appear, leave, or move; a keystroke in the edited row does not.
        .animation(.default, value: detail.rows.map(\.id))
        // The row being edited takes the keyboard and comes up above it; a new row is read back
        // from the database a moment after it starts, so the focus waits for it.
        .onChange(of: editing, initial: true) { _, editing in
            guard let editing else { return focus = nil }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(80))
                focus = .title(editing)
                withAnimation { proxy.scrollTo(editing, anchor: .center) }
            }
        }
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > titleHeight
        } action: { _, visible in
            titleVisible = visible
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.headline)
                    .opacity(titleVisible ? 1 : 0)
                    .animation(.default.speed(2), value: titleVisible)
            }
            if filter.isList, editing == nil {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("New Reminder", systemImage: "plus", action: newReminder)
                        .buttonStyle(.glassProminent)
                        .tint(color)
                }
                .visibilityPriority(.high)
            }
            if editing != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", action: done)
                        .buttonStyle(.glassProminent)
                        .tint(color)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Menu {
                        ForEach(Reminder.Ordering.allCases, id: \.self) { ordering in
                            Button { order(ordering) } label: {
                                Text(ordering.title)
                                Image(systemName: ordering.systemImage)
                            }
                        }
                    } label: {
                        Text("Sort By")
                        Text(preference.ordering.title)
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    Button(action: toggleCompleted) {
                        Text(preference.showCompleted ? "Hide Completed" : "Show Completed")
                        Image(systemName: preference.showCompleted ? "eye.slash.fill" : "eye")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }
}

extension Reminder.Filter.Detail.View {
    /// Rows edit in place only inside a list; elsewhere a tap opens details.
    private var rowActions: Reminder.Row.Actions {
        var actions = rows
        if !detail.filter.isList { actions.edit = nil }
        return actions
    }
}
