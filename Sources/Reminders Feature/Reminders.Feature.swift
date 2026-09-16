public import ComposableArchitecture2
public import Dependencies
public import Foundation
import FoundationEssentials_Extensions
import Standard_Library_Extensions
public import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
import Reminders_SQLite
public import SQLiteData
public import Tagged

extension Reminders {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Feature

            public var destination: Destination.State?
            public var filter: Reminders.Filter?
            public var editing: Reminders.Reminder.Editing?
            public var failure: String?
            public var search = Reminders.Search.Query()
            public var today: Range<Date>?
            public var detailWindow = Window<Reminders.Filter>(step: Feature.paging.step, margin: Feature.paging.margin)
            public var resultsWindow = Window<Reminders.Search.Query>(step: Feature.paging.step, margin: Feature.paging.margin)

            @DebugSnapshotIgnored @Fetch public var detail: Reminders.Filter.Detail.Contents? = nil
            @DebugSnapshotIgnored @Fetch public var overview = Reminders.Overview.Contents()
            @DebugSnapshotIgnored @Fetch public var results = Reminders.Search.Contents()
            @DebugSnapshotIgnored @Fetch(Reminders.Pending.Request()) public var pending: Set<Reminder.ID> = []

            public init() {}

            public subscript(draft id: Reminder.ID) -> Reminder.Record.Draft? {
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
            case backgroundTapped
            case clearCompletedButtonTapped
            case datePresetSelected(Reminder.ID, Reminders.Reminder.Due.Preset?)
            case deleteCompletedButtonTapped(olderThanMonths: Int?)
            case destination(Destination.Action)
            case detailEndReached
            case doneButtonTapped
            case filterTapped(Reminders.Filter)
            case listDeleted(List<Reminder>.ID)
            case listDetailsButtonTapped(List<Reminder>.ID)
            case listTapped(List<Reminder>.ID)
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
            case searchTagTapped(Tag<Reminder>.ID)
            case databaseReplaced
            case showCompletedButtonTapped
            case tagDeleted(Tag<Reminder>.ID)
            case tagTapped(Tag<Reminder>.ID)
            case timePresetSelected(Reminder.ID, Reminders.Reminder.Due.Preset.Time?)
            case titleSubmitted
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.continuousClock) var clock
        @Dependency(\.date.now) var now
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.uuid) var uuid

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .addListButtonTapped:
                    state.destination = .list(List<Reminder>.Form.Feature.State(draft: List<Reminder>.Record.Draft.create(), original: nil))
                case .appActivated:
                    state.today = calendar.day(containing: now)
                case .backgroundTapped:
                    if state.editing != nil {
                        endEditing(&state)
                    } else if case let .list(list) = state.filter {
                        startNewReminder(in: list, &state)
                    }
                case let .datePresetSelected(id, preset):
                    if state.editing?.id == id { state.editing?.draft.set(datePreset: preset, at: now, calendar: calendar) }
                case .clearCompletedButtonTapped:
                    guard let filter = state.filter, let today = state.today else { break }
                    perform { db in try Reminder.Record.deleteCompleted(in: filter, today: today).execute(db) }
                case let .deleteCompletedButtonTapped(months):
                    let query = state.search
                    let cutoff = months.map { now.subtracting($0.months, in: calendar) ?? now }
                    perform { db in try Reminder.Record.deleteCompleted(matching: query, dueBefore: cutoff).execute(db) }
                case .destination(.list(.cancelButtonTapped)), .destination(.reminder(.cancelButtonTapped)):
                    state.destination = nil
                case .detailEndReached:
                    guard let detail = state.detail else { break }
                    state.detailWindow.widen(for: detail.filter, shown: detail.rows.count, total: detail.total)
                case .destination:
                    break
                case .doneButtonTapped:
                    endEditing(&state)
                case let .filterTapped(filter):
                    state.filter = filter
                case let .listDeleted(id):
                    let replacement = List<Reminder>.ID(uuid())
                    store.addTask {
                        try await attempt {
                            try write { db in try List<Reminder>.Record.delete(id, replacement: replacement, in: db) }
                            try store.modify { $0.filter = $0.filter.flatMap { $0.removing(list: id) } }
                        }
                    }
                case let .listDetailsButtonTapped(id):
                    if let list = state.overview.list(id) {
                        state.destination = .list(List<Reminder>.Form.Feature.State(draft: List<Reminder>.Record.Draft(list), original: list))
                    }
                case let .listTapped(id):
                    state.filter = .list(id)
                case let .listsMoved(source, destination):
                    var ids = state.overview.lists.map(\.id)
                    ids.move(offsets: source, to: destination)
                    perform { db in try List<Reminder>.Record.reorder(ids).execute(db) }
                case .newReminderButtonTapped:
                    if case let .list(list) = state.filter {
                        startNewReminder(in: list, &state)
                    } else if let list = state.overview.lists.first?.id {
                        state.destination = .reminder(Reminder.Form.Feature.State(draft: Reminder.Record.Draft.create(listID: list, created: now), tags: [], original: nil))
                    }
                case let .orderingSelected(ordering):
                    guard let filter = state.filter else { break }
                    perform { db in try Reminders.Filter.Preference.set(ordering: ordering, for: filter).execute(db) }
                case let .reminderCompleteButtonTapped(id):
                    store.addTask {
                        try await attempt {
                            let status = try write { db in
                                try Reminder.Record.toggle(id).execute(db)
                                return try Reminder.Record.find(id).select(\.status).fetchOne(db)
                            }
                            try store.modify {
                                if let status, $0.editing?.id == id {
                                    $0.editing?.draft.status = status
                                    $0.editing?.original.status = status
                                }
                            }
                        }
                    }
                case let .reminderDeleted(id):
                    let session = state.editing?.id == id ? state.editing?.session : nil
                    store.addTask {
                        try await attempt {
                            try write { db in
                                try Reminder.Record.find(id).delete().execute(db)
                                if session != nil { try Reminders.Restoration.set(editing: nil).execute(db) }
                            }
                            try store.modify { $0.endEditing(session) }
                        }
                    }
                case let .reminderDetailsButtonTapped(id):
                    let editing = state.editing
                    store.addTask {
                        try await attempt(editing: editing?.session) {
                            let row = try write { db in
                                try commit(editing, in: db)
                                try Reminders.Restoration.set(editing: nil).execute(db)
                                return try Reminder.Record.find(id).rows().fetchOne(db)
                            }
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let row {
                                    $0.destination = .reminder(Reminder.Form.Feature.State(draft: Reminder.Record.Draft(row.reminder), tags: Set(row.tags.map { Tag<Reminder>.ID($0) }), original: row))
                                }
                            }
                        }
                    }
                case let .reminderTapped(id):
                    guard state.editing?.id != id else { break }
                    let editing = state.editing
                    store.addTask {
                        try await attempt(editing: editing?.session) {
                            let row = try write { db in
                                try commit(editing, in: db)
                                guard let row = try Reminder.Record.find(id).rows().fetchOne(db) else {
                                    try Reminders.Restoration.set(editing: nil).execute(db)
                                    return Reminder.Record.Row?.none
                                }
                                try Reminders.Restoration.set(editing: id).execute(db)
                                return row
                            }
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let row { $0.editing = Reminders.Reminder.Editing(row, session: uuid()) }
                            }
                        }
                    }
                case let .remindersMoved(source, destination):
                    guard let filter = state.filter else { break }
                    var ids = state.detail?.ids ?? []
                    ids.move(offsets: source, to: destination)
                    perform { db in
                        try Reminder.Record.reorder(ids, in: db)
                        try Reminders.Filter.Preference.set(ordering: .manual, for: filter).execute(db)
                    }
                case .resultsEndReached:
                    state.resultsWindow.widen(for: state.search, shown: state.results.shown, total: state.results.total)
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
                    perform { db in try Reminders.Filter.Preference.toggleShowCompleted(for: filter).execute(db) }
                case let .tagDeleted(id):
                    store.addTask {
                        try await attempt {
                            try write { db in try Tag<Reminder>.Record.delete(id).execute(db) }
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
                do {
                    let (stored, row) = try database.read { db in
                        let stored = try Reminders.Restoration.current.fetchOne(db)
                        let row = try stored?.editing.flatMap { try Reminder.Record.find($0).rows().fetchOne(db) }
                        return (stored, row)
                    }
                    if let filter = stored?.filter.flatMap(Reminders.Filter.init(key:)) { state.filter = filter }
                    if let row { state.editing = Reminders.Reminder.Editing(row, session: uuid()) }
                } catch {
                    state.failure = error.localizedDescription
                }
            }
            .onChange(of: store.today, initial: true) { _, today, state in
                guard let today else { return }
                let overview = state.$overview
                store.addTask {
                    try await attempt { try await overview.load(Reminders.Overview.Request(today: today)) }
                    try await clock.sleep(for: .seconds(max(today.upperBound.timeIntervalSince(now), 0)))
                    try store.modify { $0.today = calendar.day(containing: now) }
                }
            }
            .onChange(of: store.filter) { previous, filter, state in
                if previous != nil { endEditing(&state) }
                perform { db in try Reminders.Restoration.set(filter: filter).execute(db) }
            }
            .onChange(
                of: store.today.map {
                    Reminders.Filter.Detail.Request(
                        filter: store.filter,
                        today: $0,
                        place: store.editing?.place,
                        limit: store.filter.flatMap { store.detailWindow.limit(for: $0) }
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
            .onChange(of: Reminders.Search.Request(query: store.search, limit: store.resultsWindow.limit(for: store.search)), initial: true) { previous, request, state in
                let results = state.$results
                let (previous, query) = (previous.query, request.query)
                let typed = previous.text != query.text && previous.tokens == query.tokens && !query.text.isEmpty
                store.addTask {
                    if typed { try await clock.sleep(for: Self.searchPause) }
                    try await attempt { try await results.load(request) }
                }
            }
            .onChange(of: store.search.isActive) { _, active, state in
                if !active { state.search.showCompleted = false }
            }
            .onChange(of: store.pending, initial: true) { _, pending, _ in
                guard !pending.isEmpty else { return }
                store.addTask {
                    try await clock.sleep(for: Self.grace)
                    try await attempt { try write { db in try Reminder.Record.completePending.execute(db) } }
                }
            }
        }
    }
}

extension Reminders.Feature {
    public static let searchPause: Duration = .milliseconds(250)
    public static let grace: Duration = .seconds(5)
    public static let paging: (step: Int, margin: Int) = (300, 60)

    private func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }

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

    private func perform(_ body: @escaping (Database) throws -> Void) {
        store.addTask {
            try await attempt { try write(body) }
        }
    }

    private func startNewReminder(in list: List<Reminder>.ID, _ state: inout State) {
        let previous = state.editing
        if let filter = state.filter { state.detailWindow.open(for: filter) }
        store.addTask {
            try await attempt(editing: previous?.session) {
                let row = try write { db in
                    try commit(previous, in: db)
                    let id = try Reminder.Record.append(Reminder.Record.Draft.create(listID: list, created: now), in: db)
                    try Reminders.Restoration.set(editing: id).execute(db)
                    return try Reminder.Record.find(id).rows().fetchOne(db)
                }
                try store.modify {
                    $0.endEditing(previous?.session)
                    if let row { $0.editing = Reminders.Reminder.Editing(row, session: uuid()) }
                }
            }
        }
    }

    private func endEditing(_ state: inout State) {
        guard let editing = state.editing else { return }
        store.addTask {
            try await attempt(editing: editing.session) {
                try write { db in
                    try commit(editing, in: db)
                    try Reminders.Restoration.set(editing: nil).execute(db)
                }
                try store.modify { $0.endEditing(editing.session) }
            }
        }
    }

    private func continueEditing(_ state: inout State) {
        guard let editing = state.editing, !editing.draft.isBlank else { return endEditing(&state) }
        if let filter = state.filter { state.detailWindow.extend(for: filter, by: 1) }
        store.addTask {
            try await attempt(editing: editing.session) {
                let next = try write { db in
                    try commit(editing, in: db)
                    guard let anchor = try Reminder.Record.find(editing.id).rows().fetchOne(db) else {
                        try Reminders.Restoration.set(editing: nil).execute(db)
                        return Reminders.Reminder.Editing?.none
                    }
                    try Reminder.Record.makeRoom(after: anchor.reminder.position).execute(db)
                    let id = try Reminder.Record.add(Reminder.Record.Draft.create(listID: anchor.reminder.listID, position: anchor.reminder.position + 1, created: now), in: db)
                    try Reminders.Restoration.set(editing: id).execute(db)
                    guard let row = try Reminder.Record.find(id).rows().fetchOne(db) else { return nil }
                    var place = Reminder(anchor)
                    place.id = id
                    place.position = row.reminder.position
                    return Reminders.Reminder.Editing(draft: Reminder.Record.Draft(row.reminder), original: row.reminder, place: place, session: uuid())
                }
                try store.modify {
                    $0.endEditing(editing.session)
                    if let next { $0.editing = next }
                }
            }
        }
    }

    private func commit(_ editing: Reminders.Reminder.Editing?, in db: Database) throws {
        guard let editing else { return }
        if editing.draft.isBlank {
            try Reminder.Record.find(editing.id).delete().execute(db)
        } else if !editing.isSaved {
            guard try Reminder.Record.find(editing.id).fetchCount(db) > 0 else { return }
            try Reminder.Record.save(editing.draft).execute(db)
        }
    }
}
