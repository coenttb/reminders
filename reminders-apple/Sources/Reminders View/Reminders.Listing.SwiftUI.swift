public import ComposableArchitecture2
import Dependencies
public import Models
public import Reminder
public import Reminders
public import Reminders_Feature
import Standard_Library_Extensions
public import SwiftUI
public import Tagged

extension Reminders.Listing {
    public struct SwiftUI {
        @Bindable private var store: StoreOf<Reminders.Listing.Feature>
        private var lists: [Models.List<Reminder>]
        @Dependency(\.date.now) private var now
        @Dependency(\.calendar) private var calendar
        @Environment(\.scenePhase) private var scenePhase
        @State private var titleVisible = false
        @State private var editMode: EditMode = .inactive
        @State private var titleHeight: CGFloat = 36
        @FocusState private var focus: Reminder.Focus?

        public init(store: StoreOf<Reminders.Listing.Feature>, lists: [Models.List<Reminder>]) {
            self.store = store
            self.lists = lists
        }
    }
}

extension Reminders.Listing.SwiftUI: SwiftUI::View {
    @ViewBuilder public var body: some SwiftUI::View {
        let style = Reminders.Filter.Style(store.filter, list: list, day: calendar.component(.day, from: now))
        let (title, tint) = (style.title ?? "", style.tint)
        let contents = store.contents
        let preference = store.preference
        let editing = store.editing?.id
        let actions = Reminder.Row.Actions(
            complete: { store.send(.reminderCompleteButtonTapped($0)) },
            delete: { store.send(.reminderDeleted($0)) },
            details: { store.send(.reminderDetailsButtonTapped($0)) },
            edit: store.list.map { _ in { store.send(.reminderTapped($0)) } }
        )
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
            if preference.showCompleted {
                let count = contents.completed
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Text("\(count) Completed")
                        Text("•").font(.caption2)
                        Button("Clear") { store.send(.clearCompletedButtonTapped) }
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
            // The editing card is one view that moves between rows, so the keyboard stays with it across a Return.
            ForEach(contents.rows.enumerated().map { Reminder.Keyed(index: $0, reminder: $1, key: $1.key(editing)) }, id: \.key) { keyed in
                let (index, reminder) = (keyed.index, keyed.reminder)
                let id = reminder.id
                let completed = store.state.isShownCompleted(reminder)
                if id == editing, let editor = store.scope(\.editing) {
                    Reminder.Editor.SwiftUI(store: editor, completed: completed, color: color(reminder.list), now: now, calendar: calendar, focus: $focus)
                } else {
                    Reminder.Row.SwiftUI(reminder: reminder, completed: completed, color: color(reminder.list), now: now, calendar: calendar, actions: actions)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onAppear { if store.window.nearsEnd(index, of: shown, total: total) { store.send(.endReached) } }
                }
            }
            .onMove { store.send(.remindersMoved($0, $1)) }
            SwiftUI::Color.clear
                .frame(height: 320)
                .contentShape(.rect)
                .onTapGesture { store.send(.backgroundTapped) }
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
        // Return keeps the keyboard on the card, which has moved onto the next row by now.
        .onSubmit { if store.editing != nil { focus = .title } }
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
            if store.list != nil, editing == nil, !editMode.isEditing {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("New Reminder", systemImage: "plus") { store.send(.newReminderButtonTapped) }
                        .buttonStyle(.glassProminent)
                        .tint(tint)
                }
                .visibilityPriority(.high)
            }
            if editing != nil || editMode.isEditing {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        if editMode.isEditing { withAnimation { editMode = .inactive } } else { store.send(.doneButtonTapped) }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(tint)
                }
            }
            if !editMode.isEditing {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if store.list != nil {
                        Button("Show List Info", systemImage: "info.circle") { store.send(.listInfoButtonTapped) }
                    }
                    Button("Select Reminders", systemImage: "checkmark.circle") { withAnimation { editMode = .active } }
                    Menu {
                        ForEach(Reminders.Ordering.allCases, id: \.self) { ordering in
                            Button { store.send(.orderingSelected(ordering)) } label: {
                                if ordering == preference.ordering {
                                    Label(ordering.title, systemImage: "checkmark")
                                } else {
                                    Text(ordering.title)
                                }
                            }
                        }
                        if preference.ordering != .manual {
                            Divider()
                            ForEach([SortOrder.forward, .reverse], id: \.self) { direction in
                                Button { store.send(.directionSelected(direction)) } label: {
                                    if direction == preference.direction {
                                        Label(preference.ordering.title(direction) ?? "", systemImage: "checkmark")
                                    } else {
                                        Text(preference.ordering.title(direction) ?? "")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text("Sort By")
                        Text(preference.ordering.title)
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    Button { store.send(.showCompletedButtonTapped) } label: {
                        Text(preference.showCompleted ? "Hide Completed" : "Show Completed")
                        Image(systemName: preference.showCompleted ? "eye.slash" : "eye")
                    }
                    if store.list != nil {
                        Button("Delete List", systemImage: "trash", role: .destructive) { store.send(.listDeleteButtonTapped) }
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, store.editing != nil { store.send(.doneButtonTapped) }
        }
    }
}

extension Reminders.Listing.SwiftUI {
    private var list: Models.List<Reminder>? { store.list.flatMap { lists.first(id: $0) } }

    private func color(_ id: Models.List<Reminder>.ID) -> SwiftUI::Color {
        lists.first(id: id).map { SwiftUI::Color($0.color) } ?? .blue
    }

    private func focusEditing(_ proxy: ScrollViewProxy) {
        guard let editing = store.editing?.id, focus == nil, store.contents.rows.contains(where: { $0.id == editing }) else { return }
        focus = .title
        withAnimation { proxy.scrollTo(Reminder.Key.editor, anchor: .center) }
    }
}

extension Reminder {
    // A row's identity in the list: itself, or the editing card while it is being edited.
    enum Key: Hashable {
        case row(Reminder.ID)
        case editor
    }

    func key(_ editing: Reminder.ID?) -> Key {
        id == editing ? .editor : .row(id)
    }

    struct Keyed {
        let index: Int
        let reminder: Reminder
        let key: Key
    }
}
