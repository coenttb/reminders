public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Reminders_SQLite
public import SQLiteData
public import Tagged

extension Reminders.Listing {
    // One filter's rows, `read(page:)` observed, with the row being edited in place. The database is the
    // truth: a new row is inserted before it is edited, and the draft is written back when its session ends.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Listing.Feature

            public var filter: Reminders.Filter
            public var editing: Reminder.Editor.Feature.State?
            @DebugSnapshotIgnored @Fetch public var page = Reminders.Page()

            public init(filter: Reminders.Filter) {
                self.filter = filter
            }

            public var list: Models.List<Reminder>.ID? {
                if case let .list(id) = filter { id } else { nil }
            }

            // The draft stands in for its row until the page carries what was written.
            public var contents: Reminders.Page {
                var page = page
                if let editing, let index = page.rows.firstIndex(where: { $0.id == editing.id }) {
                    page.rows[index] = editing.draft
                }
                return page
            }

            mutating func endEditing(_ session: UUID?) {
                guard let session, editing?.session == session else { return }
                editing = nil
            }
        }

        public enum Action {
            case backgroundTapped
            case doneButtonTapped
            case editing(Reminder.Editor.Feature.Action)
            case newReminderButtonTapped
            case reminderCompleteButtonTapped(Reminder.ID)
            case reminderDeleted(Reminder.ID)
            case reminderTapped(Reminder.ID)
        }

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
                case .doneButtonTapped, .editing(.titleSubmitted):
                    endEditing(&state)
                case .editing(.completeButtonTapped):
                    state.editing?.draft.completed.toggle()
                case .newReminderButtonTapped:
                    if let list = state.list { startNewReminder(in: list, &state) }
                case let .reminderCompleteButtonTapped(id):
                    store.addTask {
                        try await store.attempt {
                            var reminder = try reminders.read(id)
                            reminder.completed.toggle()
                            try await reminders.update(reminder)
                        }
                    }
                case let .reminderDeleted(id):
                    store.addTask {
                        try await store.attempt {
                            try await reminders.delete(id)
                            try store.modify { if $0.editing?.id == id { $0.editing = nil } }
                        }
                    }
                case let .reminderTapped(id):
                    guard state.editing?.id != id else { break }
                    let editing = state.editing
                    store.addTask {
                        try await store.attempt {
                            try await commit(editing)
                            let reminder = try reminders.read(id)
                            try store.modify {
                                $0.endEditing(editing?.session)
                                $0.editing = Reminder.Editor.Feature.State(reminder, session: uuid())
                            }
                        }
                    }
                }
            }
            .ifLet(\.editing) {
                Reminder.Editor.Feature()
            }
            .onChange(of: Reminders.Read.Page.Request(page: store.filter), initial: true) { _, request, state in
                let page = state.$page
                store.addTask {
                    try await store.attempt { try await page.load(request) }
                }
            }
            // Leaving writes the draft.
            .onDismount {
                try await commit(store.editing)
            }
        }
    }
}

extension Reminders.Listing.Feature {
    private func startNewReminder(in list: Models.List<Reminder>.ID, _ state: inout State) {
        let previous = state.editing
        store.addTask {
            try await store.attempt {
                try await commit(previous)
                let reminder = Reminder(id: Reminder.ID(uuid()), list: list, created: now)
                try await reminders.create(reminder)
                try store.modify {
                    $0.endEditing(previous?.session)
                    $0.editing = Reminder.Editor.Feature.State(reminder, session: uuid())
                }
            }
        }
    }

    private func endEditing(_ state: inout State) {
        guard let editing = state.editing else { return }
        store.addTask {
            try await store.attempt {
                try await commit(editing)
                try store.modify { $0.endEditing(editing.session) }
            }
        }
    }

    // A draft is written whole when its session ends; a blank row is dropped; a row that is gone stays gone.
    private func commit(_ editing: Reminder.Editor.Feature.State?) async throws {
        guard let editing else { return }
        if editing.draft.isBlank {
            try await reminders.delete(editing.id)
        } else if !editing.isSaved {
            do {
                try await reminders.update(editing.draft)
            } catch Reminders.Update.Error.notFound {}
        }
    }
}
