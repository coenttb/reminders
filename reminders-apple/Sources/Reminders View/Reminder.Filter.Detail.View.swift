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
        private var info: (() -> Void)?
        private var delete: (() -> Void)?
        private var clearCompleted: (() -> Void)?
        @State private var titleVisible = false
        @State private var editMode: EditMode = .inactive
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
            newReminder: @escaping () -> Void,
            info: (() -> Void)? = nil,
            delete: (() -> Void)? = nil,
            clearCompleted: (() -> Void)? = nil
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
            self.info = info
            self.delete = delete
            self.clearCompleted = clearCompleted
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
                // Select mode renames the screen, as stock does (Evidence/Parity/edit-mode).
                Text(editMode.isEditing ? "Select Reminders" : title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(color)
                    .onAppear { titleHeight = proxy.size.height }
            }
            // The first row starts 106 pt under the safe area, as the stock large title leaves it.
            .frame(height: 48)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            // With completed shown, stock heads the list with "N Completed • Clear" over a rule.
            if preference.showCompleted, let clearCompleted {
                let count = detail.rows.count { $0.reminder.completed }
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Text("\(count) Completed")
                        Text("•").font(.caption2)
                        Button("Clear", action: clearCompleted)
                            .disabled(count == 0)
                            .foregroundStyle(count == 0 ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 14)
                    Divider()
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 12, trailing: 16))
                .listRowSeparator(.hidden)
            }
            // Stock rows: no separators, 10 pt above and below the text, 42 pt for a title alone.
            ForEach(detail.rows) { row in
                if row.id == editing {
                    Reminder.Editor(reminder: draft(row.id), color: row.color.swiftUI, now: now, calendar: calendar, focus: $focus, actions: editor)
                } else {
                    Reminder.Row(row.reminder, color: row.color.swiftUI, now: now, calendar: calendar, actions: rowActions)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparator(.hidden)
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
        .environment(\.defaultMinListRowHeight, 42)
        // Rows animate when they appear, leave, or move; a keystroke in the edited row does not.
        .animation(.default, value: detail.rows.map(\.id))
        // The row being edited takes the keyboard and comes up above it. A new row is read back
        // from the database a moment after it starts — longer in a long list — so the focus is
        // set once the row is among the rows, not after a fixed wait.
        .onChange(of: editing, initial: true) { _, editing in
            guard editing != nil else { return focus = nil }
            focusEditing(proxy)
        }
        .onChange(of: detail.rows.map(\.id)) { _, _ in focusEditing(proxy) }
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
            if filter.isList, editing == nil, !editMode.isEditing {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("New Reminder", systemImage: "plus", action: newReminder)
                        .buttonStyle(.glassProminent)
                        .tint(color)
                }
                .visibilityPriority(.high)
            }
            if editing != nil || editMode.isEditing {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        if editMode.isEditing { withAnimation { editMode = .inactive } } else { done() }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(color)
                }
            }
            // The stock More menu (Evidence/Parity/list-menu): Show List Info, Select Reminders,
            // Sort By with the current ordering as its subtitle and no item glyphs, Show/Hide
            // Completed, Delete List. Print is out of scope.
            if !editMode.isEditing {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if let info {
                        Button("Show List Info", systemImage: "info.circle", action: info)
                    }
                    Button("Select Reminders", systemImage: "checkmark.circle") { withAnimation { editMode = .active } }
                    // Choosing an ordering is an intent the feature writes, not state the view owns,
                    // so the items are buttons with the checkmark on the current one (as the chips do).
                    Menu {
                        ForEach(Reminder.Ordering.allCases, id: \.self) { ordering in
                            Button { order(ordering) } label: {
                                if ordering == preference.ordering {
                                    Label(ordering.title, systemImage: "checkmark")
                                } else {
                                    Text(ordering.title)
                                }
                            }
                        }
                    } label: {
                        Text("Sort By")
                        Text(preference.ordering.title)
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    Button(action: toggleCompleted) {
                        Text(preference.showCompleted ? "Hide Completed" : "Show Completed")
                        Image(systemName: preference.showCompleted ? "eye.slash" : "eye")
                    }
                    if let delete {
                        Button("Delete List", systemImage: "trash", role: .destructive, action: delete)
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
            }
        }
        .environment(\.editMode, $editMode)
        // Stock centres "No Reminders" in an empty list (Evidence/Parity/empty).
        .overlay {
            if detail.rows.isEmpty, editing == nil {
                Text("No Reminders").font(.title3).foregroundStyle(.tertiary)
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }
}

extension Reminder.Filter.Detail.View {
    /// Scrolls the edited row into view once it exists, then focuses its title. The row is
    /// focused after the scroll: a List row far down a long list has no field to focus until
    /// it has been brought on screen, and a focus set before that is dropped.
    private func focusEditing(_ proxy: ScrollViewProxy) {
        guard let editing, focus != .title(editing), focus != .notes(editing), detail.rows.contains(where: { $0.id == editing }) else { return }
        Task { @MainActor in
            withAnimation { proxy.scrollTo(editing, anchor: .center) }
            for _ in 0..<3 {
                try? await Task.sleep(for: .milliseconds(120))
                guard self.editing == editing, focus != .notes(editing) else { return }
                focus = .title(editing)
                try? await Task.sleep(for: .milliseconds(120))
                if focus == .title(editing) { return }
            }
        }
    }

    /// Rows edit in place only inside a list; elsewhere a tap opens details.
    private var rowActions: Reminder.Row.Actions {
        var actions = rows
        if !detail.filter.isList { actions.edit = nil }
        return actions
    }
}
