public import ComposableArchitecture2
public import Dependencies
public import Foundation
import FoundationEssentials_Extensions
import Standard_Library_Extensions
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
public import Reminders_SQL
import Reminders_SQLite
public import Sharing
public import SQLiteData
public import Tagged

extension Reminders {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Feature

            public var destination: Destination.State?
            public var filter: Reminders.Filter?
            public var editing: Reminder.Editing?
            public var failure: String?
            public var search = Reminders.Search.Field()
            public var today: Range<Date>?
            public var detailWindow = Window<Reminders.Filter>(
                step: Feature.paging.step,
                margin: Feature.paging.margin
            )
            public var resultsWindow = Window<Reminders.Query>(
                step: Feature.paging.step,
                margin: Feature.paging.margin
            )

            @DebugSnapshotIgnored @Fetch public var detail: Reminders.Page? = nil
            @DebugSnapshotIgnored @Fetch public var preference = Reminders.Preference(ordering: .dueDate, showCompleted: false)
            @DebugSnapshotIgnored @Fetch public var overview = Reminders.Summary()
            @DebugSnapshotIgnored @Fetch public var matches: Reminders.Page? = nil
            @DebugSnapshotIgnored @Fetch public var suggestions: [Tag<Reminder>] = []
            public var grace: [Reminder.ID: UUID] = [:]

            // The app's restoration state: the open filter and the row being edited survive a relaunch.
            @DebugSnapshotIgnored @Shared(.appStorage(Feature.filterKey)) public var filterKey: Reminders.Filter.Key? = nil
            @DebugSnapshotIgnored @Shared(.appStorage(Feature.editingKey)) public var editingID: String? = nil

            public init() {}

            public var results: Reminders.Search.Contents {
                Reminders.Search.Contents(matches, lists: overview.lists, suggestions: suggestions)
            }

            public subscript(draft id: Reminder.ID) -> Reminder? {
                get { editing?.id == id ? editing?.draft : nil }
                set {
                    guard editing?.id == id, let newValue else { return }
                    editing?.draft = newValue
                }
            }
        }

        public enum Action {
            case addListButtonTapped
            case appActivated
            case appBackgrounded
            case backgroundTapped
            case clearCompletedButtonTapped
            case datePresetSelected(Reminder.ID, Reminder.Editor.Preset?)
            case deleteCompletedButtonTapped(olderThanMonths: Int?)
            case destination(Destination.Action)
            case detailEndReached
            case doneButtonTapped
            case filterTapped(Reminders.Filter)
            case listDeleted(Models.List<Reminder>.ID)
            case listDetailsButtonTapped(Models.List<Reminder>.ID)
            case listTapped(Models.List<Reminder>.ID)
            case listsMoved(IndexSet, Int)
            case newReminderButtonTapped
            case orderingSelected(Reminders.Ordering)
            case reminderCompleteButtonTapped(Reminder.ID)
            case reminderDeleted(Reminder.ID)
            case reminderDetailsButtonTapped(Reminder.ID)
            case reminderTapped(Reminder.ID)
            case remindersMoved(IndexSet, Int)
            case resultsEndReached
            case searchCompletedButtonTapped
            case searchSubmitted
            case searchTagTapped(Tag<Reminder>)
            case databaseReplaced
            case showCompletedButtonTapped
            case tagDeleted(Tag<Reminder>)
            case tagTapped(Tag<Reminder>)
            case timePresetSelected(Reminder.ID, Reminder.Editor.Preset.Time?)
            case titleSubmitted
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.continuousClock) var clock
        @Dependency(\.date.now) var now
        @Dependency(\.reminders) var reminders
        @Dependency(\.uuid) var uuid

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .addListButtonTapped:
                    state.destination = .list(Models.List<Reminder>.Form.Feature.State(draft: Models.List<Reminder>(id: Models.List<Reminder>.ID(uuid())), original: nil))
                case .appActivated:
                    state.today = calendar.day(containing: now)
                case .appBackgrounded:
                    for id in state.grace.keys { finish(id, completed: true) }
                    state.grace = [:]
                case .backgroundTapped:
                    if state.editing != nil {
                        endEditing(&state)
                    } else if case let .list(list) = state.filter {
                        startNewReminder(in: list, &state)
                    }
                case let .datePresetSelected(id, preset):
                    if state.editing?.id == id { state.editing?.draft.set(datePreset: preset, at: now, calendar: calendar) }
                case .clearCompletedButtonTapped:
                    guard let filter = state.filter else { break }
                    perform { try reminders.delete.completed(in: filter, today: now) }
                case let .deleteCompletedButtonTapped(months):
                    let query = state.search.query
                    let cutoff = months.map { now.subtracting($0.months, in: calendar) ?? now }
                    perform { try reminders.delete.completed(matching: query, dueBefore: cutoff) }
                case .destination(.list(.cancelButtonTapped)), .destination(.reminder(.cancelButtonTapped)):
                    state.destination = nil
                case .detailEndReached:
                    guard let filter = state.filter, let detail = state.detail else { break }
                    state.detailWindow.widen(for: filter, shown: detail.rows.count, total: detail.total)
                case .destination:
                    break
                case .doneButtonTapped:
                    endEditing(&state)
                case let .filterTapped(filter):
                    state.filter = filter
                case let .listDeleted(id):
                    let replacement = Models.List<Reminder>.ID(uuid())
                    store.addTask {
                        try await attempt {
                            try reminders.lists.delete(id, replacement: replacement)
                            try store.modify { $0.filter = $0.filter.flatMap { $0.removing(list: id) } }
                        }
                    }
                case let .listDetailsButtonTapped(id):
                    if let list = state.overview.list(id) {
                        state.destination = .list(Models.List<Reminder>.Form.Feature.State(draft: list, original: list))
                    }
                case let .listTapped(id):
                    state.filter = .list(id)
                case let .listsMoved(source, destination):
                    var ids = state.overview.lists.map(\.id)
                    ids.move(offsets: source, to: destination)
                    perform { try reminders.lists.reorder(ids) }
                case .newReminderButtonTapped:
                    if case let .list(list) = state.filter {
                        startNewReminder(in: list, &state)
                    } else if let list = state.overview.lists.first?.id {
                        state.destination = .reminder(Reminder.Form.Feature.State(draft: Reminder(id: Reminder.ID(uuid()), list: list, created: now), original: nil))
                    }
                case let .orderingSelected(ordering):
                    guard let filter = state.filter else { break }
                    perform { try reminders.update.order(filter, by: ordering) }
                case let .reminderCompleteButtonTapped(id):
                    if state.grace.removeValue(forKey: id) != nil { break }
                    if state.isCompleted(id) == true {
                        finish(id, completed: false)
                    } else {
                        let token = uuid()
                        state.grace[id] = token
                        store.addTask {
                            try await clock.sleep(for: Self.grace)
                            guard store.grace[id] == token else { return }
                            try await finish(id, completed: true)
                        }
                    }
                case let .reminderDeleted(id):
                    state.grace.removeValue(forKey: id)
                    let token = state.editing?.id == id ? state.editing?.session : nil
                    store.addTask {
                        try await attempt {
                            try reminders.delete(id)
                            try store.modify { $0.endEditing(token) }
                        }
                    }
                case let .reminderDetailsButtonTapped(id):
                    let editing = state.editing
                    store.addTask {
                        try await attempt(editing: editing?.session) {
                            try commit(editing)
                            let stored = try retrieve(id)?.reminder
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let stored {
                                    $0.destination = .reminder(Reminder.Form.Feature.State(draft: stored, original: stored))
                                }
                            }
                        }
                    }
                case let .reminderTapped(id):
                    guard state.editing?.id != id else { break }
                    let editing = state.editing
                    store.addTask {
                        try await attempt(editing: editing?.session) {
                            try commit(editing)
                            let placement = try retrieve(id)
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let placement { $0.editing = Reminder.Editing(placement, session: uuid()) }
                            }
                        }
                    }
                case let .remindersMoved(source, destination):
                    guard let filter = state.filter else { break }
                    var ids = state.detail?.rows.map(\.id) ?? []
                    ids.move(offsets: source, to: destination)
                    perform { try reminders.update.reorder(ids, in: filter) }
                case .resultsEndReached:
                    guard let matches = state.matches else { break }
                    state.resultsWindow.widen(for: state.search.query, shown: matches.rows.count, total: matches.total)
                case .searchCompletedButtonTapped:
                    state.search.showCompleted.toggle()
                case .searchSubmitted:
                    state.search.commitText()
                case let .searchTagTapped(tag):
                    state.search.add(tag: tag)
                case .databaseReplaced:
                    state.filter = nil
                    state.editing = nil
                case .showCompletedButtonTapped:
                    guard let filter = state.filter else { break }
                    let shown = state.preference.showCompleted
                    perform { try reminders.update.show(completed: !shown, in: filter) }
                case let .tagDeleted(id):
                    store.addTask {
                        try await attempt {
                            try reminders.tags.delete(id)
                            try store.modify { $0.filter = $0.filter.flatMap { $0.removing(tag: id) } }
                        }
                    }
                case let .tagTapped(tag):
                    state.filter = .tags([tag])
                case let .timePresetSelected(id, preset):
                    if state.editing?.id == id { state.editing?.draft.set(timePreset: preset, at: now, calendar: calendar) }
                case .titleSubmitted:
                    continueEditing(&state)
                }
            }
            .ifLet(\.destination) {
                Destination.body
            }
            .onEvent(TagDeleted.self) { id, state in
                state.filter = state.filter.flatMap { $0.removing(tag: id) }
            }
            .onMount { state in
                state.today = calendar.day(containing: now)
                state.filter = state.filterKey.flatMap(Reminders.Filter.init(key:))
                do {
                    if let stored = state.editingID.flatMap(UUID.init(uuidString:)),
                       let placement = try retrieve(Reminder.ID(stored)) {
                        state.editing = Reminder.Editing(placement, session: uuid())
                    }
                } catch {
                    state.failure = error.localizedDescription
                }
                state.$editingID.withLock { $0 = state.editing?.id.rawValue.uuidString }
            }
            .onChange(of: store.today, initial: true) { _, today, state in
                guard let today else { return }
                let overview = state.$overview
                store.addTask {
                    try await attempt { try await overview.load(Reminders.Summary.Query(today: today)) }
                    try await clock.sleep(for: .seconds(max(today.upperBound.timeIntervalSince(now), 0)))
                    try store.modify { $0.today = calendar.day(containing: now) }
                }
            }
            .onChange(of: store.filter) { previous, filter, state in
                if previous != nil { endEditing(&state) }
                state.$filterKey.withLock { $0 = filter.map(Reminders.Filter.Key.init) }
            }
            .onChange(of: store.filter.map { Reminders.Preference.Query(for: $0) }, initial: true) { _, request, state in
                guard let request else { return }
                let preference = state.$preference
                store.addTask {
                    try await attempt { try await preference.load(request) }
                }
            }
            .onChange(of: store.editing?.id) { _, id, state in
                state.$editingID.withLock { $0 = id?.rawValue.uuidString }
            }
            .onChange(
                of: store.today.map { today in
                    Fetching(
                        store.filter.map { filter in
                            Reminders.Page.Query(
                                .filter(filter),
                                today: today,
                                including: store.editing?.place,
                                limit: store.detailWindow.limit(for: filter)
                            )
                        }
                    )
                },
                initial: true
            ) { _, request, state in
                guard let request else { return }
                let detail = state.$detail
                store.addTask {
                    try await attempt { try await detail.load(request) }
                }
            }
            .onChange(
                of: store.today.map { today in
                    Searching(
                        fetching: Fetching(
                            store.search.selection.map { selection in
                                Reminders.Page.Query(selection, today: today, including: nil, limit: store.resultsWindow.limit(for: store.search.query))
                            }
                        ),
                        committed: store.search.query,
                        typing: !store.search.text.isEmpty
                    )
                },
                initial: true
            ) { previous, searching, state in
                guard let searching else { return }
                let matches = state.$matches
                // Typing narrows the live term only; a committed token or toggle reads at once.
                let typed = searching.typing && previous?.committed == searching.committed
                store.addTask {
                    if typed { try await clock.sleep(for: Self.searchPause) }
                    try await attempt { try await matches.load(searching.fetching) }
                }
            }
            .onChange(of: store.search.suggestions, initial: true) { _, request, state in
                let suggestions = state.$suggestions
                store.addTask {
                    try await attempt { try await suggestions.load(request) }
                }
            }
            .onChange(of: store.search.isActive) { _, active, state in
                if !active { state.search.showCompleted = false }
            }
            .onDismount {
                for id in store.grace.keys { try complete(id, true) }
            }
        }
    }
}

extension Reminders.Feature {
    public static let searchPause: Duration = .milliseconds(250)
    public static let filterKey = "remindersFilter"
    public static let editingKey = "remindersEditing"
    public static let grace: Duration = .seconds(5)
    public static let paging: (step: Int, margin: Int) = (300, 60)

    private func attempt(_ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify { $0.failure = error.localizedDescription }
        }
    }

    private func attempt(editing session: UUID?, _ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify {
                $0.failure = error.localizedDescription
                if let session, $0.editing?.session == session { $0.editing?.failure = error.localizedDescription }
            }
        }
    }

    private func finish(_ id: Reminder.ID, completed: Bool) {
        store.addTask { try await finish(id, completed: completed) }
    }

    private func finish(_ id: Reminder.ID, completed: Bool) async throws {
        try await attempt {
            try complete(id, completed)
            try store.modify {
                $0.grace.removeValue(forKey: id)
                if $0.editing?.id == id {
                    $0.editing?.draft.completed = completed
                    $0.editing?.original.completed = completed
                }
            }
        }
    }

    private func retrieve(_ id: Reminder.ID) throws -> Reminders.Placement? {
        do {
            return try reminders.read(id)
        } catch Reminders.SQLite.Error.notFound {
            return nil
        }
    }

    private func complete(_ id: Reminder.ID, _ completed: Bool) throws {
        guard var reminder = try retrieve(id)?.reminder, reminder.completed != completed else { return }
        reminder.completed = completed
        _ = try reminders.update(reminder)
    }

    private func perform(_ body: @escaping () async throws -> Void) {
        store.addTask {
            try await attempt(body)
        }
    }

    private func startNewReminder(in list: Models.List<Reminder>.ID, _ state: inout State) {
        let previous = state.editing
        if let filter = state.filter { state.detailWindow.open(for: filter) }
        store.addTask {
            try await attempt(editing: previous?.session) {
                try commit(previous)
                let session = uuid()
                let placement = try reminders.create(Reminder(id: Reminder.ID(uuid()), list: list, created: now), below: nil)
                try store.modify {
                    $0.endEditing(previous?.session)
                    $0.editing = Reminder.Editing(placement, session: session)
                }
            }
        }
    }

    private func endEditing(_ state: inout State) {
        guard let editing = state.editing else { return }
        store.addTask {
            try await attempt(editing: editing.session) {
                try commit(editing)
                try store.modify { $0.endEditing(editing.session) }
            }
        }
    }

    private func continueEditing(_ state: inout State) {
        guard let editing = state.editing, !editing.draft.isBlank else { return endEditing(&state) }
        if let filter = state.filter { state.detailWindow.extend(for: filter, by: 1) }
        store.addTask {
            try await attempt(editing: editing.session) {
                try commit(editing)
                guard let anchor = try retrieve(editing.id) else {
                    try store.modify { $0.endEditing(editing.session) }
                    return
                }
                let session = uuid()
                let started = try reminders.create(Reminder(id: Reminder.ID(uuid()), list: anchor.reminder.list, created: now), below: anchor)
                var place = anchor.reminder
                place.id = started.reminder.id
                let next = Reminder.Editing(
                    draft: started.reminder,
                    original: started.reminder,
                    place: Reminders.Placement(place, position: started.position),
                    session: session
                )
                try store.modify {
                    $0.endEditing(editing.session)
                    $0.editing = next
                }
            }
        }
    }

    private func commit(_ editing: Reminder.Editing?) throws {
        guard let editing else { return }
        if editing.draft.isBlank {
            try reminders.delete(editing.id)
        } else if !editing.isSaved {
            do {
                _ = try reminders.update(editing.draft)
            } catch Reminders.SQLite.Error.notFound {}
        }
    }
}

extension Reminders.Feature {
    struct Searching: Hashable, Sendable {
        var fetching: Fetching
        var committed: Reminders.Query
        var typing: Bool
    }
}
