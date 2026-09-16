public import ComposableArchitecture2
public import Dependencies
public import Foundation
import FoundationEssentials_Extensions
import Standard_Library_Extensions
import Synchronization
public import Models
public import Reminder
public import Reminders
public import Reminders_Dependency
import Reminders_SQLite
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
            public var search = Reminders.Search.Query()
            public var today: Range<Date>?
            public var detailWindow = Window<Reminders.Filter>(step: Feature.paging.step, margin: Feature.paging.margin)
            public var resultsWindow = Window<Reminders.Search.Query>(step: Feature.paging.step, margin: Feature.paging.margin)

            @DebugSnapshotIgnored @Fetch public var detail: Reminders.Filter.Detail.Contents? = nil
            @DebugSnapshotIgnored @Fetch public var overview = Reminders.Overview.Contents()
            @DebugSnapshotIgnored @Fetch public var results = Reminders.Search.Contents()
            public var grace: [Reminder.ID: UUID] = [:]

            public init() {}

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
            case datePresetSelected(Reminder.ID, Reminder.Due.Preset?)
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
            case timePresetSelected(Reminder.ID, Reminder.Due.Preset.Time?)
            case titleSubmitted
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.continuousClock) var clock
        @Dependency(\.date.now) var now
        @Dependency(\.reminders) var reminders
        @Dependency(\.uuid) var uuid

        // Mirrors `State.grace` for the dismount flush, which runs after the state is gone.
        let armed = Armed()

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .addListButtonTapped:
                    state.destination = .list(List<Reminder>.Form.Feature.State(draft: List<Reminder>(id: List<Reminder>.ID(uuid())), original: nil))
                case .appActivated:
                    state.today = calendar.day(containing: now)
                case .appBackgrounded:
                    for id in state.grace.keys { complete(id) }
                    state.grace = [:]
                    armed.withLock { $0 = [:] }
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
                    perform { try await reminders.detail.client.clearCompleted(filter, today) }
                case let .deleteCompletedButtonTapped(months):
                    let query = state.search
                    let cutoff = months.map { now.subtracting($0.months, in: calendar) ?? now }
                    perform { try await reminders.search.client.deleteCompleted(query, cutoff) }
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
                            try await reminders.lists.client.delete(id, replacement)
                            try store.modify { $0.filter = $0.filter.flatMap { $0.removing(list: id) } }
                        }
                    }
                case let .listDetailsButtonTapped(id):
                    if let list = state.overview.list(id) {
                        state.destination = .list(List<Reminder>.Form.Feature.State(draft: list, original: list))
                    }
                case let .listTapped(id):
                    state.filter = .list(id)
                case let .listsMoved(source, destination):
                    var ids = state.overview.lists.map(\.id)
                    ids.move(offsets: source, to: destination)
                    perform { try await reminders.lists.client.reorder(ids) }
                case .newReminderButtonTapped:
                    if case let .list(list) = state.filter {
                        startNewReminder(in: list, &state)
                    } else if let list = state.overview.lists.first?.id {
                        state.destination = .reminder(Reminder.Form.Feature.State(draft: Reminder(id: Reminder.ID(uuid()), list: list, created: now), original: nil))
                    }
                case let .orderingSelected(ordering):
                    guard let filter = state.filter else { break }
                    perform { try await reminders.detail.client.setOrdering(ordering, filter) }
                case let .reminderCompleteButtonTapped(id):
                    if state.grace.removeValue(forKey: id) != nil {
                        armed.withLock { _ = $0.removeValue(forKey: id) }
                    } else if state.isCompleted(id) == true {
                        complete(id)
                    } else {
                        let token = uuid()
                        state.grace[id] = token
                        armed.withLock { $0[id] = token }
                        store.addTask {
                            try await clock.sleep(for: Self.grace)
                            guard store.grace[id] == token else { return }
                            try await finish(id)
                        }
                    }
                case let .reminderDeleted(id):
                    state.grace.removeValue(forKey: id)
                    armed.withLock { _ = $0.removeValue(forKey: id) }
                    let session = state.editing?.id == id ? state.editing?.session : nil
                    store.addTask {
                        try await attempt {
                            try await reminders.editor.client.delete(id)
                            if session != nil { try await reminders.restoration.client.setEditing(nil) }
                            try store.modify { $0.endEditing(session) }
                        }
                    }
                case let .reminderDetailsButtonTapped(id):
                    let editing = state.editing
                    store.addTask {
                        try await attempt(editing: editing?.session) {
                            try await commit(editing)
                            try await reminders.restoration.client.setEditing(nil)
                            let stored = try await reminders.editor.client.reminder(id)?.reminder
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
                            try await commit(editing)
                            let placement = try await reminders.editor.client.reminder(id)
                            try await reminders.restoration.client.setEditing(placement == nil ? nil : id)
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let placement { $0.editing = Reminder.Editing(placement, session: uuid()) }
                            }
                        }
                    }
                case let .remindersMoved(source, destination):
                    guard let filter = state.filter else { break }
                    var ids = state.detail?.ids ?? []
                    ids.move(offsets: source, to: destination)
                    perform { try await reminders.detail.client.move(ids, filter) }
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
                    perform { try await reminders.detail.client.toggleShowCompleted(filter) }
                case let .tagDeleted(id):
                    store.addTask {
                        try await attempt {
                            try await reminders.tags.client.delete(id)
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
                    let session = try reminders.restoration.client.current()
                    if let filter = session.filter { state.filter = filter }
                    if let editing = session.editing { state.editing = Reminder.Editing(editing, session: uuid()) }
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
                perform { try await reminders.restoration.client.setFilter(filter) }
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
            .onDismount {
                for id in armed.withLock({ Array($0.keys) }) { _ = try await reminders.editor.client.toggle(id) }
            }
        }
    }
}

extension Reminders.Feature {
    public static let searchPause: Duration = .milliseconds(250)
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

    private func complete(_ id: Reminder.ID) {
        store.addTask { try await finish(id) }
    }

    private func finish(_ id: Reminder.ID) async throws {
        try await attempt {
            let completed = try await reminders.editor.client.toggle(id)
            armed.withLock { _ = $0.removeValue(forKey: id) }
            try store.modify {
                $0.grace.removeValue(forKey: id)
                if let completed, $0.editing?.id == id {
                    $0.editing?.draft.completed = completed
                    $0.editing?.original.completed = completed
                }
            }
        }
    }

    private func perform(_ body: @escaping () async throws -> Void) {
        store.addTask {
            try await attempt(body)
        }
    }

    private func startNewReminder(in list: List<Reminder>.ID, _ state: inout State) {
        let previous = state.editing
        if let filter = state.filter { state.detailWindow.open(for: filter) }
        store.addTask {
            try await attempt(editing: previous?.session) {
                try await commit(previous)
                let placement = try await reminders.editor.client.start(list, nil, now)
                try await reminders.restoration.client.setEditing(placement?.reminder.id)
                try store.modify {
                    $0.endEditing(previous?.session)
                    if let placement { $0.editing = Reminder.Editing(placement, session: uuid()) }
                }
            }
        }
    }

    private func endEditing(_ state: inout State) {
        guard let editing = state.editing else { return }
        store.addTask {
            try await attempt(editing: editing.session) {
                try await commit(editing)
                try await reminders.restoration.client.setEditing(nil)
                try store.modify { $0.endEditing(editing.session) }
            }
        }
    }

    private func continueEditing(_ state: inout State) {
        guard let editing = state.editing, !editing.draft.isBlank else { return endEditing(&state) }
        if let filter = state.filter { state.detailWindow.extend(for: filter, by: 1) }
        store.addTask {
            try await attempt(editing: editing.session) {
                try await commit(editing)
                guard let anchor = try await reminders.editor.client.reminder(editing.id) else {
                    try await reminders.restoration.client.setEditing(nil)
                    try store.modify { $0.endEditing(editing.session) }
                    return
                }
                let started = try await reminders.editor.client.start(anchor.reminder.list, anchor, now)
                try await reminders.restoration.client.setEditing(started?.reminder.id)
                let next = started.map { started in
                    var place = anchor.reminder
                    place.id = started.reminder.id
                    return Reminder.Editing(
                        draft: started.reminder,
                        original: started.reminder,
                        place: Reminders.Placement(place, position: started.position),
                        session: uuid()
                    )
                }
                try store.modify {
                    $0.endEditing(editing.session)
                    if let next { $0.editing = next }
                }
            }
        }
    }

    private func commit(_ editing: Reminder.Editing?) async throws {
        guard let editing else { return }
        if editing.draft.isBlank {
            try await reminders.editor.client.delete(editing.id)
        } else if !editing.isSaved {
            _ = try await reminders.editor.client.save(editing.draft, false)
        }
    }
}

extension Reminders.Feature {
    final class Armed: Sendable {
        private let storage = Mutex<[Reminder.ID: UUID]>([:])

        func withLock<T: Sendable>(_ body: (inout sending [Reminder.ID: UUID]) throws -> sending T) rethrows -> T { try storage.withLock(body) }
    }
}
