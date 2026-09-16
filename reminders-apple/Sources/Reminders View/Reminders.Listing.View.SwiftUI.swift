public import Models
public import Reminder
public import Reminders
public import Reminders_Feature
public import SwiftUI
public import Tagged

extension Reminders.Listing.View {
    public struct SwiftUI {
        private var contents: Reminders.Listing.Client.Fetch.Result
        private var style: Reminders.Filter.Style
        private var color: (Models.List<Reminder>.ID) -> SwiftUI::Color
        private var draft: (Reminder.ID) -> Binding<Reminder>?
        private var view: Reminders.Listing.View
        @State private var titleVisible = false
        @State private var editMode: EditMode = .inactive
        @State private var titleHeight: CGFloat = 36
        @FocusState private var focus: Reminder.Focus?

        public init(
            contents: Reminders.Listing.Client.Fetch.Result,
            style: Reminders.Filter.Style,
            color: @escaping (Models.List<Reminder>.ID) -> SwiftUI::Color,
            draft: @escaping (Reminder.ID) -> Binding<Reminder>?,
            view: Reminders.Listing.View
        ) {
            self.contents = contents
            self.style = style
            self.color = color
            self.draft = draft
            self.view = view
        }
    }
}

extension Reminders.Listing.View.SwiftUI: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let (title, editing, actions) = (style.title ?? "", view.editing, view.actions)
        let tint = style.tint
        let preference = contents.preference
        let row = Reminder.Row(now: view.now, calendar: view.calendar, actions: actions.rows)
        ScrollViewReader { proxy in
        SwiftUI::List {
            GeometryReader { proxy in
                Text(editMode.isEditing ? "Select Reminders" : title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(tint)
                    .onAppear { titleHeight = proxy.size.height }
            }
            .frame(height: 48)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            if preference.showCompleted, let clearCompleted = actions.clearCompleted {
                let count = contents.completed
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
            let (shown, total) = (contents.rows.count, contents.total)
            ForEach(Array(contents.rows.enumerated()), id: \.element.id) { index, reminder in
                let id = reminder.id
                if id == editing, let draft = draft(id) {
                    Reminder.Editor.SwiftUI(
                        draft: draft,
                        color: color(reminder.list),
                        focus: $focus,
                        view: Reminder.Editor(id: id, completed: reminder.completed || view.grace.contains(id), now: view.now, calendar: view.calendar, actions: actions.editor)
                    )
                } else {
                    Reminder.Row.SwiftUI(reminder: reminder, completed: reminder.completed || view.grace.contains(id), color: color(reminder.list), view: row)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onAppear { if view.window.nearsEnd(index, of: shown, total: total) { actions.endReached() } }
                }
            }
            .onMove(perform: actions.move)
            SwiftUI::Color.clear
                .frame(height: 320)
                .contentShape(.rect)
                .onTapGesture(perform: actions.backgroundTapped)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(SwiftUI::Color.clear)
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 42)
        .animation(.default, value: contents.rows.map(\.id))
        .onChange(of: editing, initial: true) { _, editing in
            guard editing != nil else { return focus = nil }
            focusEditing(proxy)
        }
        .onChange(of: contents.rows.map(\.id)) { _, _ in focusEditing(proxy) }
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
            if let newReminder = actions.newReminder, editing == nil, !editMode.isEditing {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("New Reminder", systemImage: "plus", action: newReminder)
                        .buttonStyle(.glassProminent)
                        .tint(tint)
                }
                .visibilityPriority(.high)
            }
            if editing != nil || editMode.isEditing {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        if editMode.isEditing { withAnimation { editMode = .inactive } } else { actions.done() }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(tint)
                }
            }
            if !editMode.isEditing {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if let info = actions.info {
                        Button("Show List Info", systemImage: "info.circle", action: info)
                    }
                    Button("Select Reminders", systemImage: "checkmark.circle") { withAnimation { editMode = .active } }
                    Menu {
                        ForEach(Reminders.Ordering.allCases, id: \.self) { ordering in
                            Button { actions.order(ordering) } label: {
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
                    Button(action: actions.toggleCompleted) {
                        Text(preference.showCompleted ? "Hide Completed" : "Show Completed")
                        Image(systemName: preference.showCompleted ? "eye.slash" : "eye")
                    }
                    if let delete = actions.delete {
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
            if contents.rows.isEmpty, editing == nil {
                Text("No Reminders").font(.title3).foregroundStyle(.tertiary)
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }
}

extension Reminders.Listing.View.SwiftUI {
    private func focusEditing(_ proxy: ScrollViewProxy) {
        guard let editing = view.editing, focus != .title(editing), focus != .notes(editing), contents.rows.map(\.id).contains(editing) else { return }
        Task { @MainActor in
            withAnimation { proxy.scrollTo(editing, anchor: .center) }
            for _ in 0..<3 {
                try? await Task.sleep(for: .milliseconds(120))
                guard view.editing == editing, focus != .notes(editing) else { return }
                focus = .title(editing)
                try? await Task.sleep(for: .milliseconds(120))
                if focus == .title(editing) { return }
            }
        }
    }
}
