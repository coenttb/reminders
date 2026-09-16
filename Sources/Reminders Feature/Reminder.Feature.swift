public import ComposableArchitecture2
public import Dependencies
public import Foundation
import FoundationEssentials_Extensions
public import Organizing
public import Reminders
public import Reminders_Application
import Reminders_SQLiteData
public import SQLiteData
import Standard_Library_Extensions
public import Tagged

/// The Reminders feature. The database owns the records; the feature owns the open filter,
/// the presented form, the row being edited in place with its draft, the search input, the
/// day the screens call today, and the completion grace timer. What the screens show is read
/// from the database through `@Fetch` properties, which follow every change to the tables
/// they read; a user intent starts one targeted write, and the reads follow.
///
/// Every write runs inside a task as the synchronous `database.write`, on the store's
/// isolation, so writes land whole and in the order the user made them. A task that ends in a
/// state change checks that the session it was started for is still the one on screen before
/// it applies the change: a form is a session, and so is each editing of a row.
extension Reminder {
    /// `State.Feature` names the feature type explicitly; the macro would otherwise synthesize
    /// `typealias Feature = Feature`. `State`, `Action`, and `body` stay in the type body
    /// because the macro reads them.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminder.Feature

            /// The form sheet being shown, if any.
            public var destination: Destination.State?
            public var filter: Reminder.Filter?
            /// The reminder whose row is open for editing in the detail, with its draft.
            public var editing: Reminder.Editing?
            /// Why the last write did not happen, until the next one.
            public var failure: String?
            public var search = Reminder.Search()
            /// The day the screens call today, by the feature's calendar; nil until mounted.
            public var today: Range<Date>?
            /// The last generated seed, for the debug menu to show and replay.
            public var lastSeed: Reminder.Sample.Seed?
            /// Whether a seed is being written; the menu disables itself meanwhile.
            public var isSeeding = false

            /// The open filter, read from the database; nil while no filter is open.
            @DebugSnapshotIgnored @Fetch public var detail: Reminder.Filter.Detail? = nil
            /// The home screen, read from the database.
            @DebugSnapshotIgnored @Fetch public var overview = Reminder.Overview()
            /// The search results, read from the database.
            @DebugSnapshotIgnored @Fetch public var results = Reminder.Search.Results()
            /// The reminders in their grace period, read from the database; the grace timer is
            /// driven by this value however a reminder came to be pending. The query is
            /// declared here rather than loaded at mount, so the reader the body observes is the
            /// shared one from the first evaluation on.
            @DebugSnapshotIgnored @Fetch(Reminder.Completion.Pending.Request()) public var pending = Reminder.Completion.Pending()

            public init() {}

            /// A reminder as a draft for editing in place: the row's draft, or a placeholder once
            /// editing has ended. A write to any other reminder is dropped, so a field committing
            /// after editing ended cannot bring a deleted row back. A subscript, so a view binds
            /// to it through a key path (`$store[draft: id]`) rather than a closure-built binding.
            public subscript(draft id: Reminder.ID) -> Reminder {
                get {
                    if let editing, editing.id == id { return editing.draft }
                    return Reminder(id: id, list: overview.lists.first?.id ?? List<Reminder>.ID(Self.noList))
                }
                set {
                    guard editing?.id == id else { return }
                    editing?.draft = newValue
                }
            }

            /// The list a placeholder draft names when there is no list at all; never stored.
            private static let noList = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        }

        public enum Action {
            case addListButtonTapped
            /// The app came to the foreground: the day may have changed while it was away.
            case appActivated
            case backgroundTapped
            case clearCompletedButtonTapped
            case datePresetSelected(Reminder.ID, Reminder.Due.Preset?)
            case deleteCompletedButtonTapped(olderThanMonths: Int?)
            case destination(Destination.Action)
            case doneButtonTapped
            case filterTapped(Reminder.Filter)
            case listDeleted(List<Reminder>.ID)
            case listDetailsButtonTapped(List<Reminder>.ID)
            case listTapped(List<Reminder>.ID)
            case listsMoved(IndexSet, Int)
            case newReminderButtonTapped
            case orderingSelected(Reminder.Ordering)
            case reminderCompleteButtonTapped(Reminder.ID)
            case reminderDeleted(Reminder.ID)
            case reminderDetailsButtonTapped(Reminder.ID)
            case reminderTapped(Reminder.ID)
            case remindersMoved(IndexSet, Int)
            case searchCompletedButtonTapped
            case searchSubmitted
            case searchTagTapped(Tag<Reminder>.ID)
            case seedButtonTapped
            /// A generated sample at a scale; no seed value draws a fresh one.
            case seedGenerated(Reminder.Sample.Scale, seed: UInt64?)
            case deleteEverythingButtonTapped
            case showCompletedButtonTapped
            case tagDeleted(Tag<Reminder>.ID)
            case tagTapped(Tag<Reminder>.ID)
            case timePresetSelected(Reminder.ID, Reminder.Due.Preset.Time?)
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
                // A tap on the empty part of a list ends editing, or starts a new row in an idle list.
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
                // A blank name is no list and no reminder: the sheet stays up. It also stays up
                // until the write has succeeded; a failed one leaves the draft to try again, and
                // a save under way is not started twice.
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
                // The tags table owns the tags; the draft follows what it accepted, so adding a tag
                // that exists in another case attaches the existing tag instead of a twin. A failure
                // is the form's, and the draft is untouched; a success clears the last failure.
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
                // Inside a list the new reminder is a row edited in place; from the home it is the sheet.
                case .newReminderButtonTapped:
                    if case let .list(list) = state.filter {
                        startNewReminder(in: list, &state)
                    } else if let list = state.overview.lists.first?.id {
                        state.destination = .reminder(Reminder.Draft.Feature.State(reminder: Reminder(id: Reminder.ID(uuid()), list: list, created: now), isNew: true, session: uuid()))
                    }
                case let .orderingSelected(ordering):
                    guard let filter = state.filter else { break }
                    perform { db in try Reminder.Filter.Preference.Record.set(ordering: ordering, for: filter).execute(db) }
                // The grace timer follows the stored status through `pending`: the period
                // starts once the toggle is stored, and not at all when the write fails.
                case let .reminderCompleteButtonTapped(id):
                    store.addTask {
                        try await attempt {
                            let completion = try write { db in
                                try Reminder.Record.toggle(id).execute(db)
                                return try Reminder.Record.find(id).rows().fetchOne(db)?.value.completion
                            }
                            // The row being edited shows its draft, so the draft follows the stored completion.
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
                                if session != nil { try Reminder.Session.Record.set(editing: nil).execute(db) }
                            }
                            try store.modify { $0.endEditing(session) }
                        }
                    }
                // The sheet opens on the stored reminder, once the row's draft is written; a draft
                // that cannot be written keeps its row open instead.
                case let .reminderDetailsButtonTapped(id):
                    let editing = state.editing
                    store.addTask {
                        try await attempt {
                            let reminder = try write { db in
                                try commit(editing, in: db)
                                try Reminder.Session.Record.set(editing: nil).execute(db)
                                return try Reminder.Record.find(id).rows().fetchOne(db)?.value
                            }
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let reminder { $0.destination = .reminder(Reminder.Draft.Feature.State(reminder: reminder, isNew: false, session: uuid())) }
                            }
                        }
                    }
                // The row opens on the stored reminder, once the previous row's draft is written.
                case let .reminderTapped(id):
                    guard state.editing?.id != id else { break }
                    let editing = state.editing
                    store.addTask {
                        try await attempt {
                            let reminder = try write { db in
                                try commit(editing, in: db)
                                guard let reminder = try Reminder.Record.find(id).rows().fetchOne(db)?.value else {
                                    try Reminder.Session.Record.set(editing: nil).execute(db)
                                    return Reminder?.none
                                }
                                try Reminder.Session.Record.set(editing: id).execute(db)
                                return reminder
                            }
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let reminder { $0.editing = Reminder.Editing(reminder, session: uuid()) }
                            }
                        }
                    }
                case let .remindersMoved(source, destination):
                    guard let filter = state.filter else { break }
                    var ids = state.detail?.rows.map(\.id) ?? []
                    ids.move(offsets: source, to: destination)
                    perform { db in
                        try Reminder.Record.reorder(ids, in: db)
                        try Reminder.Filter.Preference.Record.set(ordering: .manual, for: filter).execute(db)
                    }
                case .searchCompletedButtonTapped:
                    state.search.showCompleted.toggle()
                case .searchSubmitted:
                    state.search.commitText()
                case let .searchTagTapped(tag):
                    state.search.add(tag: tag)
                case .seedButtonTapped:
                    let sample = Reminder.sample(at: now)
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
                    state.lastSeed = Reminder.Sample.Seed(scale: scale, value: value)
                    state.isSeeding = true
                    store.addTask {
                        try await attempt {
                            // Generated and written off the main actor: a hundred thousand rows take seconds.
                            let sample = Reminder.Sample.generated(scale, seed: value, at: now, calendar: calendar)
                            try await database.write { db in try sample.replace(in: db) }
                            try store.modify {
                                $0.filter = nil
                                $0.editing = nil
                            }
                        }
                        try store.modify { $0.isSeeding = false }
                    }
                case .deleteEverythingButtonTapped:
                    let empty = Reminder.Sample(lists: [List(id: List<Reminder>.ID(uuid()))])
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
                    perform { db in try Reminder.Filter.Preference.Record.toggleShowCompleted(for: filter).execute(db) }
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
            // The first run fills the database with the sample; any later run restores the open
            // filter and the row being edited, before anything else runs. A grace period that was
            // running when the app last quit resumes as soon as `pending` reads it. A read
            // that fails is a failure, not a first run.
            .onMount { state in
                state.today = calendar.day(containing: now)
                let sample = Reminder.sample(at: now)
                // Restored synchronously, so the detail's first read already sees the filter: a
                // filter set from a task after the mount left the detail unread on relaunch.
                do {
                    let (stored, reminder) = try write { db in
                        try sample.initialize(in: db)
                        let stored = try Reminder.Session.Record.state.fetchOne(db)?.session
                        let reminder = try stored?.editing.flatMap { try Reminder.Record.find($0).rows().fetchOne(db)?.value }
                        return (stored, reminder)
                    }
                    if let filter = stored?.filter { state.filter = filter }
                    if let reminder { state.editing = Reminder.Editing(reminder, session: uuid()) }
                } catch {
                    state.failure = error.localizedDescription
                }
            }
            // The day decides the overview counts and the Today filter: it is read again when the
            // day changes, and the change is scheduled on the feature's clock for midnight.
            .onChange(of: store.today, initial: true) { _, today, state in
                guard let today else { return }
                let overview = state.$overview
                store.addTask {
                    try await attempt { try await overview.load(Reminder.Overview.Request(today: today)) }
                    try await clock.sleep(for: .seconds(max(today.upperBound.timeIntervalSince(now), 0)))
                    try store.modify { $0.today = calendar.day(containing: now) }
                }
            }
            // Leaving a filter ends the row being edited, as the stock app does. A row is only
            // ever edited inside a filter, so a change from no filter is the mount restoring the
            // filter and its row together, not the user leaving one.
            .onChange(of: store.filter) { previous, filter, state in
                if previous != nil { endEditing(&state) }
                perform { db in try Reminder.Session.Record.set(filter: filter).execute(db) }
            }
            // The detail is read again for another filter or day, or when a row starts or stops
            // being edited: the row being edited keeps the place it had, whatever the ordering says.
            .onChange(of: DetailQuery(filter: store.filter, place: store.editing?.place, today: store.today), initial: true) { _, query, state in
                guard let today = query.today else { return }
                let detail = state.$detail
                store.addTask {
                    try await attempt { try await detail.load(Reminder.Filter.Detail.Request(filter: query.filter, today: today, place: query.place)) }
                }
            }
            // Typing is written as it happens: each change writes what differs from what the
            // database holds, so a relaunch mid-edit finds the text. A failed write keeps the
            // draft and its reason; the next change, or Done, writes the whole difference again.
            .onChange(of: store.editing?.autosave) { _, autosave, _ in
                guard let autosave, autosave.draft != autosave.saved else { return }
                store.addTask {
                    do {
                        let exists = try write { db in
                            let exists = try update(from: autosave.saved, to: autosave.draft, in: db)
                            if !exists { try Reminder.Session.Record.set(editing: nil).execute(db) }
                            return exists
                        }
                        try store.modify {
                            guard $0.editing?.session == autosave.session else { return }
                            if exists {
                                $0.editing?.saved = autosave.draft
                                $0.editing?.failure = nil
                            } else {
                                // Deleted by another writer: the session ends, and nothing is recreated.
                                $0.editing = nil
                            }
                        }
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        try store.modify {
                            guard $0.editing?.session == autosave.session else { return }
                            $0.editing?.failure = error.localizedDescription
                            $0.failure = error.localizedDescription
                        }
                    }
                }
            }
            // Typing waits for a pause before it is read: each read is two passes over every
            // reminder, and the earlier task is cancelled by the next character, so a word costs
            // one read rather than one per character. A token, the completed toggle, or a
            // cleared field is read at once.
            .onChange(of: store.search, initial: true) { previous, search, state in
                let results = state.$results
                let typed = previous.text != search.text && previous.tokens == search.tokens && !search.text.isEmpty
                store.addTask {
                    if typed { try await clock.sleep(for: Self.searchPause) }
                    try await attempt { try await results.load(Reminder.Search.Results.Request(search: search)) }
                }
            }
            .onChange(of: store.search.isActive) { _, active, state in
                if !active { state.search.showCompleted = false }
            }
            // The grace period: `Pending.grace` after the set of pending reminders last changed,
            // every reminder still pending is completed. The set is the observed query: the
            // feature is remounted when it changes, by this feature's own write or another
            // writer's, and every change restarts the period, so the latest tap, reversal, or
            // external change gets the full period, and a set that empties cancels the timer.
            // The mount counts as a change: a set already loaded when the feature mounts is a
            // period that was running when the app last quit, and it resumes here.
            .onChange(of: store.pending, initial: true) { _, pending, _ in
                guard !pending.isEmpty else { return }
                store.addTask {
                    try await clock.sleep(for: Reminder.Completion.Pending.grace)
                    try await attempt { try write { db in try Reminder.Record.completePending.execute(db) } }
                }
            }
        }
    }
}

extension Reminder.Feature {
    /// How long typing in the search field pauses before the reminders are read.
    public static let searchPause: Duration = .milliseconds(250)

    /// The database access the tasks use. Synchronous, on the store's isolation: a write lands
    /// whole, in the order the actions came, before anything else runs. TCA26 cancels the
    /// earlier task of a repeated action, but a task that never suspends cannot observe that;
    /// it runs to its end, state change included, which is why each such change checks its
    /// session first.
    private func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }

    /// Runs database work inside a task; a failure is kept for the user to see, and a
    /// cancellation ends the task quietly.
    private func attempt(_ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify { $0.failure = error.localizedDescription }
        }
    }

    /// As `attempt`, for work done for a form: the failure is the form's, if that form is
    /// still up; a form that closed meanwhile is told nothing.
    private func attempt(form session: UUID, _ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify { $0.modifyReminderForm(session) { $0.failure = error.localizedDescription } }
        }
    }

    /// Runs one write as a task of the feature.
    private func perform(_ body: @escaping (Database) throws -> Void) {
        store.addTask {
            try await attempt { try write(body) }
        }
    }

    /// Opens an empty reminder at the end of a list for editing, once the row being edited is
    /// written. The row takes its place in the manual order from the database, so the session
    /// starts once the row is stored.
    private func startNewReminder(in list: List<Reminder>.ID, _ state: inout State) {
        let previous = state.editing
        let id = Reminder.ID(uuid())
        store.addTask {
            try await attempt {
                let reminder = try write { db in
                    try commit(previous, in: db)
                    try Reminder.Record.insert { Reminder.Record(Reminder(id: id, list: list, created: now)) }.execute(db)
                    try Reminder.Record.placeLast(id).execute(db)
                    try Reminder.Session.Record.set(editing: id).execute(db)
                    return try Reminder.Record.find(id).rows().fetchOne(db)?.value
                }
                try store.modify {
                    $0.endEditing(previous?.session)
                    if let reminder { $0.editing = Reminder.Editing(reminder, session: uuid()) }
                }
            }
        }
    }

    /// Ends the row being edited: a blank one is removed, any other one is written as typed.
    /// A draft that cannot be written stays open with its reason, so Done can try again.
    private func endEditing(_ state: inout State) {
        guard let editing = state.editing else { return }
        store.addTask {
            try await attempt {
                try write { db in
                    try commit(editing, in: db)
                    try Reminder.Session.Record.set(editing: nil).execute(db)
                }
                try store.modify { $0.endEditing(editing.session) }
            }
        }
    }

    /// Return in the title: a blank row ends editing; a titled row is written and an empty row
    /// opens directly beneath it, in the same list, sorted as its neighbour until editing ends
    /// so it stays beneath under any ordering.
    private func continueEditing(_ state: inout State) {
        guard let editing = state.editing, !editing.draft.isBlank else { return endEditing(&state) }
        let id = Reminder.ID(uuid())
        store.addTask {
            try await attempt {
                let next = try write { db in
                    try commit(editing, in: db)
                    guard let anchor = try Reminder.Record.find(editing.id).rows().fetchOne(db)?.value else {
                        try Reminder.Session.Record.set(editing: nil).execute(db)
                        return Reminder.Editing?.none
                    }
                    let next = Reminder(id: id, list: anchor.list, position: anchor.position + 1, created: now)
                    try Reminder.Record.makeRoom(after: anchor.position).execute(db)
                    try Reminder.Record.insert { Reminder.Record(next) }.execute(db)
                    try Reminder.Session.Record.set(editing: id).execute(db)
                    var place = anchor
                    place.id = id
                    place.position = next.position
                    return Reminder.Editing(draft: next, saved: next, place: place, session: uuid())
                }
                try store.modify {
                    $0.endEditing(editing.session)
                    if let next { $0.editing = next }
                }
            }
        }
    }

    /// Writes an editing session back: a blank draft deletes the row, any other writes what
    /// differs from what the database holds. A row deleted meanwhile stays deleted. Throws when
    /// the write fails, so the session it belongs to stays open.
    private func commit(_ editing: Reminder.Editing?, in db: Database) throws {
        guard let editing else { return }
        if editing.draft.isBlank {
            try Reminder.Record.find(editing.id).delete().execute(db)
        } else if !editing.isSaved {
            try update(from: editing.saved, to: editing.draft, in: db)
        }
    }

    /// Writes what a draft changed against the value the database holds: the changed columns,
    /// the tags removed, and the tags added. Nothing is inserted, so a row deleted meanwhile
    /// stays deleted; returns whether the row still exists.
    @discardableResult
    private func update(from saved: Reminder, to draft: Reminder, in db: Database) throws -> Bool {
        guard try Reminder.Record.find(saved.id).fetchCount(db) > 0 else { return false }
        try Reminder.Record.changes(from: saved, to: draft)?.execute(db)
        let removed = saved.tags.subtracting(draft.tags)
        if !removed.isEmpty { try Reminder.Tagging.detach(removed, from: saved.id).execute(db) }
        try Reminder.Tagging.attach(draft.tags.subtracting(saved.tags), to: saved.id, in: db)
        return true
    }

    /// Saves the reminder form and closes it; the result is the form's only while that form
    /// is still the one presented.
    private func save(_ form: Reminder.Draft.Feature.State) {
        store.addTask {
            do {
                let saved = try write { db in
                    if form.isNew {
                        try Reminder.Record.insert { Reminder.Record(form.reminder) }.execute(db)
                        try Reminder.Record.placeLast(form.reminder.id).execute(db)
                        try Reminder.Tagging.attach(form.reminder.tags, to: form.reminder.id, in: db)
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

extension Reminder.Feature.State {
    /// Closes the editing session, if it is still the one open; a later session is left alone.
    fileprivate mutating func endEditing(_ session: UUID?) {
        guard let session, editing?.session == session else { return }
        editing = nil
    }

    fileprivate mutating func modifyReminderForm(_ session: UUID, _ body: (inout Reminder.Draft.Feature.State) -> Void) {
        guard case var .reminder(form) = destination, form.session == session else { return }
        body(&form)
        destination = .reminder(form)
    }

    fileprivate mutating func modifyListForm(_ session: UUID, _ body: (inout List<Reminder>.Draft.Feature.State) -> Void) {
        guard case var .list(form) = destination, form.session == session else { return }
        body(&form)
        destination = .list(form)
    }
}

extension Reminder.Editing {
    /// What an autosave writes: the draft against what the database holds, for a session.
    fileprivate var autosave: Autosave { Autosave(session: session, draft: draft, saved: saved) }

    fileprivate struct Autosave: Equatable {
        var session: UUID
        var draft: Reminder
        var saved: Reminder
    }
}

/// What the detail read depends on.
private struct DetailQuery: Equatable {
    var filter: Reminder.Filter?
    var place: Reminder?
    var today: Range<Date>?
}
