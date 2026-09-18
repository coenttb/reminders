public import ComposableArchitecture2
public import Dependencies
public import Foundation
import FoundationEssentials_Extensions
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Reminders_SQLite
public import Sharing
public import SQLiteData
import Standard_Library_Extensions
public import Tagged

extension Reminders.Listing {
    // One filter's rows: `read(page:)` observed, with the row being edited and the completions in grace.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable, Gracing {
            public typealias Feature = Reminders.Listing.Feature

            public var filter: Reminders.Filter
            public var today: Date
            public var window = Window<Reminders.Filter>(step: Feature.paging.step, margin: Feature.paging.margin)
            public var editing: Reminder.Editor.Feature.State?
            public var grace: [Reminder.ID: UUID] = [:]
            public var reopening: Set<Reminder.ID> = []
            public var deleting: Set<Reminder.ID> = []

            @DebugSnapshotIgnored @Fetch public var page = Reminders.Page()
            // The row being continued is shown beneath its anchor before the page carries it.
            public var contents: Reminders.Page {
                var page = shown(page)
                if let editing, !page.rows.contains(where: { $0.id == editing.id }), let anchor = editing.anchor {
                    _ = page.insert(editing.draft, after: anchor)
                } else if let editing, editing.anchor == nil, editing.original.isBlank, preference.showCompleted {
                    page.moveToEnd(editing.id)
                }
                return page
            }
            @DebugSnapshotIgnored @Fetch public var preference = Reminders.Preference(ordering: .dueDate, showCompleted: false)
            // The Sort By pickers bind here; the stored preference follows through the feature, and leads it back.
            public var ordering: Reminders.Ordering = .dueDate
            public var direction: SortOrder = .forward

            public init(filter: Reminders.Filter, today: Date) {
                self.filter = filter
                self.today = today
            }

            public var list: Models.List<Reminder>.ID? {
                if case let .list(id) = filter { id } else { nil }
            }

            public func isCompleted(_ id: Reminder.ID) -> Bool? {
                if editing?.id == id { return editing?.original.isCompleted }
                return page.rows.first { $0.id == id }?.isCompleted
            }

            public mutating func finished(_ id: Reminder.ID, completed: Date?) {
                if editing?.id == id {
                    editing?.draft.completed = completed
                    editing?.original.completed = completed
                }
            }

            mutating func endEditing(_ session: UUID?) {
                guard let session, editing?.session == session else { return }
                editing = nil
            }
        }

        public enum Action {
            case backgroundTapped
            case clearCompletedButtonTapped
            case directionSelected(SortOrder)
            case doneButtonTapped
            case editing(Reminder.Editor.Feature.Action)
            case endReached
            case graceEnded
            case listDeleteButtonTapped
            case listInfoButtonTapped
            case newReminderButtonTapped
            case orderingSelected(Reminders.Ordering)
            case reminderCompleteButtonTapped(Reminder.ID)
            case reminderDeleted(Reminder.ID)
            case reminderDetailsButtonTapped(Reminder.ID)
            case reminderRecovered(Reminder.ID)
            case reminderDropped(Reminder.ID, into: Reminders.Section)
            case reminderTapped(Reminder.ID)
            case sectionAddTapped(Reminders.Section)
            case remindersMoved(IndexSet, Int)
            case showCompletedButtonTapped
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.continuousClock) var clock
        @Dependency(\.date) var date
        @Dependency(\.date.now) var now
        @Dependency(\.reminders) var reminders
        @Dependency(\.uuid) var uuid

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .backgroundTapped:
                    if state.editing != nil {
                        endEditing(&state)
                    } else if let list = state.list {
                        startNewReminder(in: list, &state)
                    }
                case .clearCompletedButtonTapped:
                    let filter = state.filter
                    perform { try await reminders.delete.completed(in: filter, today: now) }
                case .doneButtonTapped:
                    endEditing(&state)
                case .editing(.completeButtonTapped):
                    if let id = state.editing?.id { completion.tapped(id, &state) }
                case .editing(.customDateTapped):
                    if let id = state.editing?.id { details(id, part: .dates, &state) }
                case .editing(.detailsButtonTapped):
                    if let id = state.editing?.id { details(id, &state) }
                case .editing(.titleSubmitted):
                    continueEditing(&state)
                case .editing:
                    break
                case .endReached:
                    state.window.widen(for: state.filter, shown: state.page.rows.count, total: state.page.total)
                case .graceEnded:
                    completion.finishAll(&state)
                case .listDeleteButtonTapped, .listInfoButtonTapped:
                    break
                case .newReminderButtonTapped:
                    if let list = state.list { startNewReminder(in: list, &state) }
                case let .orderingSelected(ordering):
                    state.ordering = ordering
                case let .directionSelected(direction):
                    state.direction = direction
                case let .reminderCompleteButtonTapped(id):
                    completion.tapped(id, &state)
                case let .reminderDeleted(id):
                    state.grace.removeValue(forKey: id)
                    state.deleting.insert(id)
                    // On Recently Deleted a delete is for good; elsewhere the row moves there.
                    let permanently = state.filter == .recentlyDeleted
                    store.addTask {
                        for id in store.deleting where store.deleting.contains(id) {
                            try await store.attempt {
                                if permanently { try await reminders.delete.permanently(id) } else { try await reminders.delete(id) }
                                try store.modify {
                                    $0.deleting.remove(id)
                                    if $0.editing?.id == id { $0.editing = nil }
                                }
                            }
                        }
                    }
                case let .reminderDetailsButtonTapped(id):
                    details(id, &state)
                case let .reminderRecovered(id):
                    state.deleting.insert(id)
                    store.addTask {
                        try await store.attempt {
                            try await reminders.update.recover(id)
                            try store.modify { $0.deleting.remove(id) }
                        }
                    }
                case let .reminderDropped(id, section):
                    // A row dragged onto a day or a part of the day takes that date; the row being edited moves with its draft.
                    guard state.editing?.id != id else { break }
                    let (now, calendar) = (now, calendar)
                    perform {
                        guard var reminder = try completion.retrieve(id)?.reminder, let due = section.due(moving: reminder.due, at: now, calendar: calendar) else { return }
                        reminder.due = due
                        _ = try await reminders.update(reminder)
                    }
                case let .sectionAddTapped(section):
                    startNewReminder(in: state.list, due: section.due(at: now, calendar: calendar), &state)
                case let .reminderTapped(id):
                    guard state.editing?.id != id else { break }
                    let editing = state.editing
                    store.addTask {
                        try await attempt(editing: editing?.session) {
                            try await commit(editing)
                            let placement = try completion.retrieve(id)
                            try store.modify {
                                $0.endEditing(editing?.session)
                                if let placement { $0.editing = Reminder.Editor.Feature.State(placement, session: uuid()) }
                            }
                        }
                    }
                case let .remindersMoved(source, destination):
                    let filter = state.filter
                    var ids = state.page.rows.map(\.id)
                    ids.move(offsets: source, to: destination)
                    perform { try await reminders.update.reorder(ids, in: filter) }
                case .showCompletedButtonTapped:
                    let (filter, shown) = (state.filter, state.preference.showCompleted)
                    perform { try await reminders.update.show(completed: !shown, in: filter) }
                }
            }
            .ifLet(\.editing) {
                Reminder.Editor.Feature()
            }
            .onChange(of: store.preference, initial: true) { _, preference, state in
                state.ordering = preference.ordering
                state.direction = preference.direction
            }
            .onChange(of: store.ordering) { _, ordering, state in
                guard ordering != state.preference.ordering else { return }
                let filter = state.filter
                perform { try await reminders.update.order(filter, by: ordering) }
            }
            .onChange(of: store.direction) { _, direction, state in
                guard direction != state.preference.direction else { return }
                let filter = state.filter
                perform { try await reminders.update.turn(filter, direction) }
            }
            .onChange(of: Reminders.Read.Preference.Request(for: store.filter), initial: true) { _, request, state in
                let preference = state.$preference
                store.addTask {
                    try await store.attempt { try await preference.load(request) }
                }
            }
            .onChange(
                of: Reminders.Read.Page.Request(page: store.filter, today: store.today, including: store.editing?.place, limit: store.window.limit(for: store.filter)),
                initial: true
            ) { _, request, state in
                let page = state.$page
                store.addTask {
                    try await store.attempt { try await page.load(request) }
                }
            }
            // Leaving writes the draft and what is still in grace.
            .onDismount {
                try await commit(store.editing)
                try await completion.finish(store.grace.keys)
            }
        }
    }
}

extension Reminders.Listing.Feature {
    public static var grace: Duration { Reminders.Completion<State, Action>.grace }
    public static let paging: (step: Int, margin: Int) = (300, 60)

    private var completion: Reminders.Completion<State, Action> {
        Reminders.Completion(store: store, reminders: reminders, clock: clock, now: date, uuid: uuid)
    }

    private func attempt(editing session: UUID?, _ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify {
                if let session, $0.editing?.session == session { $0.editing?.failure = error.localizedDescription }
            }
            try store.post(key: Reminders.Feature.Failed.self, value: error.localizedDescription)
        }
    }

    private func perform(_ body: @escaping () async throws -> Void) {
        store.addTask {
            try await store.attempt(body)
        }
    }

    private func details(_ id: Reminder.ID, part: Reminder.Form.Feature.State.Part = .all, _ state: inout State) {
        let editing = state.editing
        store.addTask {
            try await attempt(editing: editing?.session) {
                try await commit(editing)
                let stored = try completion.retrieve(id)?.reminder
                try store.modify { $0.endEditing(editing?.session) }
                guard let stored else { return }
                switch part {
                case .all: try store.post(key: Reminders.Feature.ReminderDetailsRequested.self, value: stored)
                case .dates: try store.post(key: Reminders.Feature.ReminderDatesRequested.self, value: stored)
                }
            }
        }
    }

    // A smart list starts its rows in the default list, the first one, as the stock app does.
    private func startNewReminder(in list: Models.List<Reminder>.ID?, due: Reminder.Due? = nil, _ state: inout State) {
        let previous = state.editing
        store.addTask {
            try await attempt(editing: previous?.session) {
                try await commit(previous)
                guard let list = try list ?? reminders.read().lists.first?.id else { return }
                let session = uuid()
                let placement = try await reminders.create(Reminder(id: Reminder.ID(uuid()), list: list, due: due, created: now), below: nil)
                // The window and the row change together: one page request, one load.
                try store.modify {
                    $0.window.open(for: $0.filter)
                    $0.endEditing(previous?.session)
                    $0.editing = Reminder.Editor.Feature.State(placement, session: session)
                }
            }
        }
    }

    private func endEditing(_ state: inout State) {
        guard let editing = state.editing else { return }
        store.addTask {
            try await attempt(editing: editing.session) {
                try await commit(editing)
                try store.modify { $0.endEditing(editing.session) }
            }
        }
    }

    // Return moves the editing onto the next row at once, so the keyboard passes from field to field in one
    // update; the row is written beneath its anchor afterwards and the page catches up.
    private func continueEditing(_ state: inout State) {
        guard let editing = state.editing, !editing.draft.isBlank else { return endEditing(&state) }
        guard let anchor = try? completion.retrieve(editing.id) else { return endEditing(&state) }
        let session = uuid()
        let started = Reminder(id: Reminder.ID(uuid()), list: editing.draft.list, created: now)
        // The next row sits beneath the draft as it is about to be written, not beneath the row as it was stored.
        var place = editing.draft
        place.id = started.id
        state.window.extend(for: state.filter, by: 1)
        state.editing = Reminder.Editor.Feature.State(
            draft: started,
            original: started,
            place: Reminders.Placement(place, position: anchor.position + 1),
            anchor: editing.id,
            session: session
        )
        store.addTask {
            try await attempt(editing: editing.session) {
                try await commit(editing)
                _ = try await reminders.create(started, below: anchor)
            }
        }
    }

    // A draft is written whole when its session ends; a blank row is dropped; a row that is gone stays gone.
    private func commit(_ editing: Reminder.Editor.Feature.State?) async throws {
        guard let editing else { return }
        if editing.draft.isBlank {
            try await reminders.delete.permanently(editing.id)
        } else if !editing.isSaved {
            do {
                _ = try await reminders.update(editing.draft)
            } catch Reminders.Update.Error.notFound {}
        }
    }
}
