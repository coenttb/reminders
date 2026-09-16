public import Foundation
public import Reminders
public import Reminders_Interface
public import SwiftUI

extension Reminders.Filter.Detail {
    public struct View {
        private var title: String
        private var detail: Reminders.Filter.Detail
        private var editing: Reminder.ID?
        private var now: Date
        private var calendar: Calendar
        private var draft: (Reminder.ID) -> Binding<Reminder>
        private var rows: Reminder.Row.Actions
        private var editor: Reminder.Editor.Actions
        private var done: () -> Void
        private var backgroundTapped: () -> Void
        private var move: (IndexSet, Int) -> Void
        private var order: (Reminders.Ordering) -> Void
        private var toggleCompleted: () -> Void
        private var newReminder: () -> Void
        private var endReached: () -> Void
        private var info: (() -> Void)?
        private var delete: (() -> Void)?
        private var clearCompleted: (() -> Void)?
        @State private var titleVisible = false
        @State private var editMode: EditMode = .inactive
        @State private var titleHeight: CGFloat = 36
        @FocusState private var focus: Reminder.Focus?

        public init(
            _ detail: Reminders.Filter.Detail,
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
            order: @escaping (Reminders.Ordering) -> Void,
            toggleCompleted: @escaping () -> Void,
            newReminder: @escaping () -> Void,
            endReached: @escaping () -> Void,
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
            self.endReached = endReached
            self.info = info
            self.delete = delete
            self.clearCompleted = clearCompleted
        }
    }
}

extension Reminders.Filter.Detail.View: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let filter = detail.filter
        let color = filter.color(list: detail.color)
        let preference = detail.preference
        ScrollViewReader { proxy in
        SwiftUI.List {
            GeometryReader { proxy in
                Text(editMode.isEditing ? "Select Reminders" : title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(color)
                    .onAppear { titleHeight = proxy.size.height }
            }
            .frame(height: 48)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            if preference.showCompleted, let clearCompleted {
                let count = detail.completedCount
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
            let (shown, total) = (detail.rows.count, detail.total)
            ForEach(Array(detail.rows.enumerated()), id: \.element.id) { index, row in
                if row.id == editing {
                    Reminder.Editor(reminder: draft(row.id), color: SwiftUI.Color(row.color), now: now, calendar: calendar, focus: $focus, actions: editor)
                } else {
                    Reminder.Row(row.reminder, color: SwiftUI.Color(row.color), now: now, calendar: calendar, actions: rowActions)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onAppear { if Reminders.Window<Reminders.Filter>.nearsEnd(index, of: shown, total: total) { endReached() } }
                }
            }
            .onMove(perform: move)
            SwiftUI.Color.clear
                .frame(height: 320)
                .contentShape(.rect)
                .onTapGesture(perform: backgroundTapped)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(SwiftUI.Color.clear)
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 42)
        .animation(.default, value: detail.ids)
        .onChange(of: editing, initial: true) { _, editing in
            guard editing != nil else { return focus = nil }
            focusEditing(proxy)
        }
        .onChange(of: detail.ids) { _, _ in focusEditing(proxy) }
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
            if !editMode.isEditing {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if let info {
                        Button("Show List Info", systemImage: "info.circle", action: info)
                    }
                    Button("Select Reminders", systemImage: "checkmark.circle") { withAnimation { editMode = .active } }
                    Menu {
                        ForEach(Reminders.Ordering.allCases, id: \.self) { ordering in
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
        .overlay {
            if detail.rows.isEmpty, editing == nil {
                Text("No Reminders").font(.title3).foregroundStyle(.tertiary)
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }
}

extension Reminders.Filter.Detail.View {
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

    private var rowActions: Reminder.Row.Actions {
        var actions = rows
        if !detail.filter.isList { actions.edit = nil }
        return actions
    }
}
