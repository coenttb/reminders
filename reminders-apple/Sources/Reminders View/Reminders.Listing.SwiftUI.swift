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
        // Today, Scheduled, and Completed gather rows from every list and name the list in each row, as the stock app does.
        let named = store.list == nil && !store.filter.groupsByList
        let deleted = store.filter == .recentlyDeleted
        let actions = Reminder.Row.Actions(
            complete: { store.send(.reminderCompleteButtonTapped($0)) },
            delete: { store.send(.reminderDeleted($0)) },
            details: { if !deleted { store.send(.reminderDetailsButtonTapped($0)) } },
            // A row edits in place inside its list and inside All; the other smart lists open the details until a
            // continued row learns to keep the filter it was started in.
            edit: store.list != nil || store.filter == .all ? { store.send(.reminderTapped($0)) } : nil,
            recover: deleted ? { store.send(.reminderRecovered($0)) } : nil
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
            if deleted {
                Text("Reminders are permanently deleted after \(Int(Reminder.retention / 86_400)) days.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
            } else if preference.showCompleted {
                let count = contents.completed
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Text("\(count) Completed")
                        Text("•").font(.footnote)
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
                .listRowInsets(EdgeInsets(top: 15, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
            }
            let (shown, total) = (contents.rows.count, contents.total)
            let sectioned = store.filter.sectionsByDay
            let completion = store.filter == .completed
            // One flat run of items, so a long-press drag reorders across sections: a row dropped under another
            // section's header takes that section's date.
            let items = Item.items(of: contents.sections, editing: editing, sectioned: sectioned, filter: store.filter, now: now, calendar: calendar)
            ForEach(items) { item in
                let key = contents.sections[item.section].key
                switch item.kind {
                case let .row(index, reminder):
                    let id = reminder.id
                    let completed = store.state.isShownCompleted(reminder)
                    // The editing card is one view that moves between rows, so the keyboard stays with it across a Return.
                    if id == editing, let editor = store.scope(\.editing) {
                        Reminder.Editor.SwiftUI(store: editor, completed: completed, color: color(reminder.list), now: now, calendar: calendar, focus: $focus)
                    } else {
                        Reminder.Row.SwiftUI(reminder: reminder, list: named ? lists.first(id: reminder.list)?.title : nil, dated: sectioned && key.showsTimeAlone, completion: completion, completed: completed, color: sectioned ? tint : color(reminder.list), now: now, calendar: calendar, actions: actions)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowSeparator(.hidden)
                            .onAppear { if store.window.nearsEnd(index, of: shown, total: total) { store.send(.endReached) } }
                    }
                case .add:
                    Button { store.send(.sectionAddTapped(key)) } label: {
                        Image(systemName: "circle.dotted")
                            .foregroundStyle(SwiftUI::Color(.systemGray3))
                            .font(.title2)
                            .frame(width: 26, height: 20)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("New Reminder")
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowSeparator(.hidden)
                case .landing:
                    // A section without rows keeps a landing row, so a drag can settle in it.
                    SwiftUI::Color.clear
                        .frame(height: 12)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    case let .header(titled):
                    Group {
                        if case let .list(id) = key, let list = lists.first(id: id) {
                            Text(list.title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(SwiftUI::Color(list.color))
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                // Overdue days and previous days share one title above the first of their run.
                                if titled, let title = key.groupTitle {
                                    Text(title).font(.title2.weight(.bold)).foregroundStyle(SwiftUI::Color.primary)
                                }
                                key.header.view(month: calendar, now: now, empty: contents.sections[item.section].rows.isEmpty)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 2, trailing: 16))
                    .listRowSeparator(.hidden)
                case let .rule(thin):
                    // A 2 pt rule closes every section; between consecutive days it thins to a dotted line.
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: thin ? 1 : 2)
                        .opacity(thin ? 0.6 : 1)
                        .listRowInsets(EdgeInsets(top: -5, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
            }
            .onMove { source, destination in
                guard let from = source.first, case let .row(index, reminder) = items[from].kind else { return }
                // The item the row lands before names its section; landing before a section's header means the end of the one above.
                let landing = destination < items.count ? items[destination] : items[items.count - 1]
                let target = landing.kind.isHeader && destination > 0 ? items[destination - 1].section : landing.section
                if target != items[from].section {
                    store.send(.reminderDropped(reminder.id, into: contents.sections[target].key))
                } else if !sectioned {
                    let to = items[..<min(destination, items.count)].count { $0.kind.isRow }
                    store.send(.remindersMoved(IndexSet(integer: index), to))
                }
            }
            SwiftUI::Color.clear
                .frame(height: 320)
                .contentShape(.rect)
                .onTapGesture { store.send(.backgroundTapped) }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(SwiftUI::Color.clear)
        }
        .listStyle(.plain)
        // Rows are 42 pt by their own insets; the section headers and rules take only the height they draw.
        .environment(\.defaultMinListRowHeight, 1)
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
                    if !deleted {
                    Menu {
                        // Pickers in a menu draw the stock checkmark column.
                        Picker("Sort By", selection: $store.ordering) {
                            ForEach(Reminders.Ordering.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                        if preference.ordering != .manual {
                            Picker("Direction", selection: $store.direction) {
                                ForEach([SortOrder.forward, .reverse], id: \.self) { Text(preference.ordering.title($0) ?? "").tag($0) }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
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
        withAnimation { proxy.scrollTo(Item.ID.row(.editor), anchor: .center) }
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
}

extension Reminders.Listing.SwiftUI {
    // What the list draws, in order: a section's header, its rows, an add circle or a landing row, and its rule.
    struct Item: Identifiable {
        enum Kind {
            case header(titled: Bool)
            case row(Int, Reminder)
            case add
            case landing
            case rule(thin: Bool)

            var isHeader: Bool { if case .header = self { true } else { false } }
            var isRow: Bool { if case .row = self { true } else { false } }
        }

        let id: ID
        let section: Int
        let kind: Kind

        enum ID: Hashable {
            case header(Reminders.Section), row(Reminder.Key), add(Reminders.Section), landing(Reminders.Section), rule(Reminders.Section)
        }

        static func items(of sections: [Reminders.Page.Section], editing: Reminder.ID?, sectioned: Bool, filter: Reminders.Filter, now: Date, calendar: Calendar) -> [Item] {
            var items: [Item] = []
            var index = 0
            for (offset, section) in sections.enumerated() {
                let key = section.key
                let list: Bool = { if case .list = key { true } else { false } }()
                if list || key.header != .none {
                    let titled = key.groupTitle != nil && (offset == 0 || sections[offset - 1].key.groupTitle != key.groupTitle)
                    items.append(Item(id: .header(key), section: offset, kind: .header(titled: titled)))
                }
                for reminder in section.rows {
                    items.append(Item(id: .row(reminder.key(editing)), section: offset, kind: .row(index, reminder)))
                    index += 1
                }
                if editing == nil, key.offersAdd(in: sections, for: filter, at: now, calendar: calendar) {
                    items.append(Item(id: .add(key), section: offset, kind: .add))
                } else if sectioned, key.acceptsDrops, section.rows.isEmpty {
                    items.append(Item(id: .landing(key), section: offset, kind: .landing))
                }
                if sectioned, key != .overdue(day: nil) {
                    let next = offset + 1 < sections.count ? sections[offset + 1].key : nil
                    let thin = next.map { $0.isDay && (key.isDay || key == .tomorrow) && $0.groupTitle == key.groupTitle } ?? false
                    items.append(Item(id: .rule(key), section: offset, kind: .rule(thin: thin)))
                }
            }
            return items
        }
    }
}
