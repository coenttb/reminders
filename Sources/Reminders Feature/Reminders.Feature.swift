public import ComposableArchitecture2
public import Dependencies
public import Foundation
import FoundationEssentials_Extensions
public import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_Sample
import Reminders_SQL
import Reminders_SQLite
public import SQLiteData
import Standard_Library_Extensions
public import Tagged

extension Reminders {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Feature

            public var destination: Destination.State?
            public var filter: Reminders.Filter?
            public var editing: Reminders.Reminder.Editing?
            public var failure: String?
            public var search = Reminders.Search()
            public var today: Range<Date>?
            public var lastSeed: Reminders.Sample.Seed?
            public var isSeeding = false
            public var detailWindow = Reminders.Window<Reminders.Filter>()
            public var resultsWindow = Reminders.Window<Reminders.Search>()

            @DebugSnapshotIgnored @Fetch public var detail: Reminders.Filter.Detail? = nil
            @DebugSnapshotIgnored @Fetch public var overview = Reminders.Overview()
            @DebugSnapshotIgnored @Fetch public var results = Reminders.Search.Results()
            @DebugSnapshotIgnored @Fetch(Reminders.Pending.Request()) public var pending = Reminders.Pending()

            public init() {}

            public subscript(draft id: Reminder.ID) -> Reminder {
                get {
                    if let editing, editing.id == id { return editing.draft }
                    return Reminder(id: id, list: overview.lists.first?.id ?? List<Reminder>.ID(Self.noList), created: .distantPast)
                }
                set {
                    guard editing?.id == id else { return }
                    editing?.draft = newValue
                }
            }

            private static let noList = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
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
            case seedButtonTapped
            case seedGenerated(Reminders.Sample.Scale, seed: UInt64?)
            case deleteEverythingButtonTapped
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
        @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .addListButtonTapped:
                    state.destination = .list(List<Reminder>.Draft.Feature.State(list: List(id: List<Reminder>.ID(uuid())), isNew: true, session: uuid()))
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
                    let search = state.search
                    let cutoff = months.map { now.subtracting($0.months, in: calendar) ?? now }
                    perform { db in try Reminder.Record.deleteCompleted(matching: search, dueBefore: cutoff).execute(db) }
                case .destination(.list(.cancelButtonTapped)), .destination(.reminder(.cancelButtonTapped)):
                    state.destination = nil
                case .detailEndReached:
                    guard let detail = state.detail else { break }
                    state.detailWindow.widen(for: detail.filter, shown: detail.rows.count, total: detail.total)
                case .destination(.list(.saveButtonTapped)):
                    guard case var .list(form) = state.destination, !form.list.isBlank, !form.isSaving else { break }
                    form.isSaving = true
                    state.destination = .list(form)
                    save(form)
                case .destination(.reminder(.saveButtonTapped)):
                    guard case var .reminder(form) = state.destination, !form.reminder.isBlank, !form.isSaving else { break }
                    form.isSaving = true
                    state.destination = .reminder(form)
                    save(form)
                case let .destination(.reminder(.tagAdded(title))):
                    guard case let .reminder(form) = state.destination else { break }
                    store.addTask {
                        try await attempt(form: form.session) {
                            guard let tag = try write({ db in try Tag<Reminder>.Record.add(title, in: db) }) else { return }
                            try store.modify {
                                $0.modifyReminderForm(form.session) {
                                    $0.reminder.tags.insert(tag)
                                    $0.failure = nil
                                }
                            }
                        }
                    }
                case let .destination(.reminder(.tagDeleted(id))):
                    guard case let .reminder(form) = state.destination else { break }
                    store.addTask {
                        try await attempt(form: form.session) {
                            try write { db in try Tag<Reminder>.Record.delete(id).execute(db) }
                            try store.modify {
                                $0.filter = $0.filter.flatMap { $0.removing(tag: id) }
                                $0.modifyReminderForm(form.session) {
                                    $0.reminder.tags.remove(id)
                                    $0.failure = nil
                                }
                            }
                        }
                    }
                case let .destination(.reminder(.tagRenamed(id, title))):
                    guard case let .reminder(form) = state.destination else { break }
                    store.addTask {
                        try await attempt(form: form.session) {
                            guard let renamed = try write({ db in try Tag<Reminder>.Record.rename(id, to: title, in: db) }) else { return }
                            try store.modify {
                                $0.modifyReminderForm(form.session) { form in
                                    form.reminder.tags.replace(id, with: renamed)
                                    form.failure = nil
                                }
                            }
                        }
                    }
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
                    if let list = state.overview.list(id) { state.destination = .list(List<Reminder>.Draft.Feature.State(list: list, isNew: false, session: uuid())) }
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
                        state.destination = .reminder(Reminder.Draft.Feature.State(reminder: Reminder(id: Reminder.ID(uuid()), list: list, created: now), isNew: true, session: uuid()))
                    }
                case let .orderingSelected(ordering):
                    guard let filter = state.filter else { break }
                    perform { db in try Reminders.Filter.Preference.Record.set(ordering: ordering, for: filter).execute(db) }
                case let .reminderCompleteButtonTapped(id):
                    store.addTask {
                        try await attempt {
                            let completion = try write { db in
                                try Reminder.Record.toggle(id).execute(db)
                                return try Reminder.Record.find(id).rows().fetchOne(db).map(Reminder.init)?.completion
                            }
                            try store.modify {
                                if let completion, $0.editing?.id == id {
                                    $0.editing?.draft.completion = completion
                                    $0.editing?.saved.completion = completion
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
                                if session != nil { try Reminders.Session.Record.set(editing: nil).execute(db) }
                            }
                            try store.modify { $0.endEditing(session) }
                        }
                    }
                case let .reminderDetailsButtonTapped(id):
                    let editing = state.editing
                    store.addTask {
                        try await attempt(editing: editing?.session) {
                            let reminder = try write { db in
                                try commit(editing, in: db)
                                try Reminders.Session.Record.set(editing: nil).execute(db)
                                return try Reminder.Record.find(id).rows().fetchOne(db).map(Reminder.init)
                            }
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let reminder { $0.destination = .reminder(Reminder.Draft.Feature.State(reminder: reminder, isNew: false, session: uuid())) }
                            }
                        }
                    }
                case let .reminderTapped(id):
                    guard state.editing?.id != id else { break }
                    let editing = state.editing
                    store.addTask {
                        try await attempt(editing: editing?.session) {
                            let reminder = try write { db in
                                try commit(editing, in: db)
                                guard let reminder = try Reminder.Record.find(id).rows().fetchOne(db).map(Reminder.init) else {
                                    try Reminders.Session.Record.set(editing: nil).execute(db)
                                    return Reminder?.none
                                }
                                try Reminders.Session.Record.set(editing: id).execute(db)
                                return reminder
                            }
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let reminder { $0.editing = Reminders.Reminder.Editing(reminder, session: uuid()) }
                            }
                        }
                    }
                case let .remindersMoved(source, destination):
                    guard let filter = state.filter else { break }
                    var ids = state.detail?.rows.map(\.id) ?? []
                    ids.move(offsets: source, to: destination)
                    perform { db in
                        try Reminder.Record.reorder(ids, in: db)
                        try Reminders.Filter.Preference.Record.set(ordering: .manual, for: filter).execute(db)
                    }
                case .resultsEndReached:
                    state.resultsWindow.widen(for: state.search, shown: state.results.shown, total: state.results.total)
                case .searchCompletedButtonTapped:
                    state.search.showCompleted.toggle()
                case .searchSubmitted:
                    state.search.commitText()
                case let .searchTagTapped(tag):
                    state.search.add(tag: tag)
                case .seedButtonTapped:
                    let sample = Reminders.sample(at: now)
                    store.addTask {
                        try await attempt {
                            try write { db in try sample.replace(in: db) }
                            try store.modify {
                                $0.filter = nil
                                $0.editing = nil
                            }
                        }
                    }
                case let .seedGenerated(scale, seed):
                    let value = seed ?? withRandomNumberGenerator { UInt64.random(in: .min ... .max, using: &$0) }
                    state.lastSeed = Reminders.Sample.Seed(scale: scale, value: value)
                    state.isSeeding = true
                    store.addTask {
                        try await attempt {
                            let sample = Reminders.Sample.generated(scale, seed: value, at: now, calendar: calendar)
                            try await database.write { db in try sample.replace(in: db) }
                            try store.modify {
                                $0.filter = nil
                                $0.editing = nil
                            }
                        }
                        try store.modify { $0.isSeeding = false }
                    }
                case .deleteEverythingButtonTapped:
                    let empty = Reminders.Sample(lists: [List(id: List<Reminder>.ID(uuid()))])
                    store.addTask {
                        try await attempt {
                            try write { db in try empty.replace(in: db) }
                            try store.modify {
                                $0.filter = nil
                                $0.editing = nil
                            }
                        }
                    }
                case .showCompletedButtonTapped:
                    guard let filter = state.filter else { break }
                    perform { db in try Reminders.Filter.Preference.Record.toggleShowCompleted(for: filter).execute(db) }
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
            .onMount { state in
                state.today = calendar.day(containing: now)
                let sample = Reminders.sample(at: now)
                do {
                    let (stored, reminder) = try write { db in
                        try sample.initialize(in: db)
                        let stored = try Reminders.Session.Record.state.fetchOne(db).map(Reminders.Session.init)
                        let reminder = try stored?.editing.flatMap { try Reminder.Record.find($0).rows().fetchOne(db).map(Reminder.init) }
                        return (stored, reminder)
                    }
                    if let filter = stored?.filter { state.filter = filter }
                    if let reminder { state.editing = Reminders.Reminder.Editing(reminder, session: uuid()) }
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
                perform { db in try Reminders.Session.Record.set(filter: filter).execute(db) }
            }
            .onChange(of: DetailQuery(filter: store.filter, place: store.editing?.place, today: store.today, limit: store.filter.flatMap { store.detailWindow.limit(for: $0) }), initial: true) { _, query, state in
                guard let today = query.today else { return }
                let detail = state.$detail
                store.addTask {
                    try await attempt { try await detail.load(Reminders.Filter.Detail.Request(filter: query.filter, today: today, place: query.place, limit: query.limit)) }
                }
            }
            .onChange(of: ResultsQuery(search: store.search, limit: store.resultsWindow.limit(for: store.search)), initial: true) { previous, query, state in
                let results = state.$results
                let (previous, search) = (previous.search, query.search)
                let typed = previous.text != search.text && previous.tokens == search.tokens && !search.text.isEmpty
                store.addTask {
                    if typed { try await clock.sleep(for: Self.searchPause) }
                    try await attempt { try await results.load(Reminders.Search.Request(search: search, limit: query.limit)) }
                }
            }
            .onChange(of: store.search.isActive) { _, active, state in
                if !active { state.search.showCompleted = false }
            }
            .onChange(of: store.pending, initial: true) { _, pending, _ in
                guard !pending.isEmpty else { return }
                store.addTask {
                    try await clock.sleep(for: Reminders.Pending.grace)
                    try await attempt { try write { db in try Reminder.Record.completePending.execute(db) } }
                }
            }
        }
    }
}

extension Reminders.Feature {
    public static let searchPause: Duration = .milliseconds(250)

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

    private func attempt(form session: UUID, _ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify { $0.modifyReminderForm(session) { $0.failure = error.localizedDescription } }
        }
    }

    private func perform(_ body: @escaping (Database) throws -> Void) {
        store.addTask {
            try await attempt { try write(body) }
        }
    }

    private func startNewReminder(in list: List<Reminder>.ID, _ state: inout State) {
        let previous = state.editing
        let id = Reminder.ID(uuid())
        if let filter = state.filter { state.detailWindow.open(for: filter) }
        store.addTask {
            try await attempt(editing: previous?.session) {
                let reminder = try write { db in
                    try commit(previous, in: db)
                    try Reminder.Record.insert { Reminder.Record.Draft(Reminder(id: id, list: list, created: now)) }.execute(db)
                    try Reminder.Record.placeLast(id).execute(db)
                    try Reminders.Session.Record.set(editing: id).execute(db)
                    return try Reminder.Record.find(id).rows().fetchOne(db).map(Reminder.init)
                }
                try store.modify {
                    $0.endEditing(previous?.session)
                    if let reminder { $0.editing = Reminders.Reminder.Editing(reminder, session: uuid()) }
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
                    try Reminders.Session.Record.set(editing: nil).execute(db)
                }
                try store.modify { $0.endEditing(editing.session) }
            }
        }
    }

    private func continueEditing(_ state: inout State) {
        guard let editing = state.editing, !editing.draft.isBlank else { return endEditing(&state) }
        let id = Reminder.ID(uuid())
        if let filter = state.filter { state.detailWindow.extend(for: filter, by: 1) }
        store.addTask {
            try await attempt(editing: editing.session) {
                let next = try write { db in
                    try commit(editing, in: db)
                    guard let anchor = try Reminder.Record.find(editing.id).rows().fetchOne(db).map(Reminder.init) else {
                        try Reminders.Session.Record.set(editing: nil).execute(db)
                        return Reminders.Reminder.Editing?.none
                    }
                    let next = Reminder(id: id, list: anchor.list, position: anchor.position + 1, created: now)
                    try Reminder.Record.makeRoom(after: anchor.position).execute(db)
                    try Reminder.Record.insert { Reminder.Record.Draft(next) }.execute(db)
                    try Reminders.Session.Record.set(editing: id).execute(db)
                    var place = anchor
                    place.id = id
                    place.position = next.position
                    return Reminders.Reminder.Editing(draft: next, saved: next, place: place, session: uuid())
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
            try update(from: editing.saved, to: editing.draft, in: db)
        }
    }

    @discardableResult
    private func update(from saved: Reminder, to draft: Reminder, in db: Database) throws -> Bool {
        guard try Reminder.Record.find(saved.id).fetchCount(db) > 0 else { return false }
        try Reminder.Record.changes(from: saved, to: draft)?.execute(db)
        let removed = saved.tags.subtracting(draft.tags)
        if !removed.isEmpty { try Reminders.Tagging.detach(removed, from: saved.id).execute(db) }
        try Reminders.Tagging.attach(draft.tags.subtracting(saved.tags), to: saved.id, in: db)
        return true
    }

    private func save(_ form: Reminder.Draft.Feature.State) {
        store.addTask {
            do {
                let saved = try write { db in
                    if form.isNew {
                        try Reminder.Record.insert { Reminder.Record.Draft(form.reminder) }.execute(db)
                        try Reminder.Record.placeLast(form.reminder.id).execute(db)
                        try Reminders.Tagging.attach(form.reminder.tags, to: form.reminder.id, in: db)
                        return true
                    }
                    return try update(from: form.original, to: form.reminder, in: db)
                }
                try store.modify {
                    guard case let .reminder(current) = $0.destination, current.session == form.session else { return }
                    if saved {
                        $0.destination = nil
                    } else {
                        $0.modifyReminderForm(form.session) { $0.fail("This reminder was deleted.") }
                    }
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                try store.modify { $0.modifyReminderForm(form.session) { $0.fail(error.localizedDescription) } }
            }
        }
    }

    private func save(_ form: List<Reminder>.Draft.Feature.State) {
        store.addTask {
            do {
                let saved = try write { db in
                    if form.isNew {
                        try List<Reminder>.Record.insert { List<Reminder>.Record(form.list) }.execute(db)
                        try List<Reminder>.Record.placeLast(form.list.id).execute(db)
                        return true
                    }
                    guard try List<Reminder>.Record.find(form.original.id).fetchCount(db) > 0 else { return false }
                    try List<Reminder>.Record.changes(from: form.original, to: form.list)?.execute(db)
                    return true
                }
                try store.modify {
                    guard case let .list(current) = $0.destination, current.session == form.session else { return }
                    if saved {
                        $0.destination = nil
                    } else {
                        $0.modifyListForm(form.session) { $0.fail("This list was deleted.") }
                    }
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                try store.modify { $0.modifyListForm(form.session) { $0.fail(error.localizedDescription) } }
            }
        }
    }
}
