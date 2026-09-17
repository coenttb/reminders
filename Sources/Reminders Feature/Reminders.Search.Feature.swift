public import ComposableArchitecture2
public import Dependencies
public import Foundation
import FoundationEssentials_Extensions
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Reminders_SQLite
public import SQLiteData
import Standard_Library_Extensions
public import Tagged

extension Reminders.Search {
    // The search: `read(search:)` and `tags.suggest` observed as the field changes.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable, Gracing {
            public typealias Feature = Reminders.Search.Feature

            public var field = Reminders.Search.Field()
            public var today: Date
            public var window = Window<Reminders.Query>(step: Reminders.Listing.Feature.paging.step, margin: Reminders.Listing.Feature.paging.margin)
            public var grace: [Reminder.ID: UUID] = [:]
            public var reopening: Set<Reminder.ID> = []
            public var deleting: Set<Reminder.ID> = []

            @DebugSnapshotIgnored @Fetch public var matches: Reminders.Page? = nil
            @DebugSnapshotIgnored @Fetch public var suggestions: [Tag<Reminder>] = []

            public init(today: Date) {
                self.today = today
            }

            public func isCompleted(_ id: Reminder.ID) -> Bool? {
                matches?.rows.first { $0.id == id }?.completed
            }

            public mutating func finished(_ id: Reminder.ID, completed: Bool) {}
        }

        public enum Action {
            case completedButtonTapped
            case deleteCompletedButtonTapped(olderThanMonths: Int?)
            case endReached
            case graceEnded
            case reminderCompleteButtonTapped(Reminder.ID)
            case reminderDeleted(Reminder.ID)
            case reminderDetailsButtonTapped(Reminder.ID)
            case submitted
            case tagTapped(Tag<Reminder>)
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
                case .completedButtonTapped:
                    state.field.showCompleted.toggle()
                case let .deleteCompletedButtonTapped(months):
                    let query = state.field.query
                    let cutoff = months.map { now.subtracting($0.months, in: calendar) ?? now }
                    store.addTask {
                        try await store.attempt { try await reminders.delete.completed(matching: query, dueBefore: cutoff) }
                    }
                case .endReached:
                    guard let matches = state.matches else { break }
                    state.window.widen(for: state.field.query, shown: matches.rows.count, total: matches.total)
                case .graceEnded:
                    completion.finishAll(&state)
                case let .reminderCompleteButtonTapped(id):
                    completion.tapped(id, &state)
                case let .reminderDeleted(id):
                    state.grace.removeValue(forKey: id)
                    state.deleting.insert(id)
                    store.addTask {
                        for id in store.deleting where store.deleting.contains(id) {
                            try await store.attempt {
                                try await reminders.delete(id)
                                try store.modify { $0.deleting.remove(id) }
                            }
                        }
                    }
                case let .reminderDetailsButtonTapped(id):
                    store.addTask {
                        try await store.attempt {
                            if let stored = try completion.retrieve(id)?.reminder {
                                try store.post(key: Reminders.Feature.ReminderDetailsRequested.self, value: stored)
                            }
                        }
                    }
                case .submitted:
                    state.field.commitText()
                case let .tagTapped(tag):
                    state.field.add(tag: tag)
                }
            }
            .onChange(
                of: Searching(
                    fetching: Reminders.Fetching(
                        store.field.effective.map { query in
                            Reminders.Read.Search.Request(search: query, today: store.today, limit: store.window.limit(for: store.field.query))
                        }
                    ),
                    committed: store.field.query,
                    typing: !store.field.text.isEmpty
                ),
                initial: true
            ) { previous, searching, state in
                let matches = state.$matches
                // Typing narrows the live term only; a committed token or toggle reads at once.
                let typed = searching.typing && previous.committed == searching.committed
                store.addTask {
                    if typed { try await clock.sleep(for: Self.pause) }
                    try await store.attempt { try await matches.load(searching.fetching) }
                }
            }
            .onChange(of: store.field.suggestions, initial: true) { _, request, state in
                let suggestions = state.$suggestions
                store.addTask {
                    try await store.attempt { try await suggestions.load(request) }
                }
            }
            .onChange(of: store.field.isActive) { _, active, state in
                if !active { state.field.showCompleted = false }
            }
            // Leaving writes what is still in grace.
            .onDismount {
                try await completion.finish(store.grace.keys)
            }
        }
    }
}

extension Reminders.Search.Feature {
    public static let pause: Duration = .milliseconds(250)

    private var completion: Reminders.Completion<State, Action> {
        Reminders.Completion(store: store, reminders: reminders, clock: clock, uuid: uuid)
    }

    struct Searching: Hashable, Sendable {
        var fetching: Reminders.Fetching<Reminders.Read.Search.Request>
        var committed: Reminders.Query
        var typing: Bool
    }
}
