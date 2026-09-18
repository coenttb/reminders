public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Interface_ComposableArchitecture
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Standard_Library_Extensions
public import Tagged

extension Reminders.Read.Page {
    // One page, `read(page:)` followed, with the row being edited in place. The database is the truth: a new
    // row is inserted before it is edited, and the draft is written back when its session ends. The feature
    // observes and calls, nothing else; calls ride `writes`.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public var observing: Observing<Reminders.Read.Page>.State
            public var editing: Reminders.Update.Feature.State?
            @StoreTaskID public var writes

            public init(page filter: Reminders.Read.Filter) {
                self.observing = .init(page: filter)
            }

            public var list: Models.List<Reminder>.ID? {
                if case let .list(id) = observing.request.filter { id } else { nil }
            }

            // The draft stands in for its row until the page carries what was written.
            public var contents: Reminders.Read.Page.Value {
                var page = observing.value ?? Value()
                if let editing, let index = page.rows.firstIndex(where: { $0.id == editing.id }) {
                    page.rows[index] = editing.reminder
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
            case call(Reminders.Call)
            case doneButtonTapped
            case editing(Reminders.Update.Feature.Action)
            case newReminderButtonTapped
            case observing(Observing<Reminders.Read.Page>.Action)
            case reminderTapped(Reminder.ID)
        }

        @Dependency(\.date.now) var now
        @Dependency(\.reminders) var reminders
        @Dependency(\.uuid) var uuid

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Features {
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
                    // A deleted row's draft is dropped with it.
                    case let .call(.delete(request)):
                        if state.editing?.id == request.id { state.editing = nil }
                    case .call, .observing:
                        break
                    case .editing(.completeButtonTapped):
                        state.editing?.completed.toggle()
                    case .newReminderButtonTapped:
                        if let list = state.list { startNewReminder(in: list, &state) }
                    // Editing starts from the row the page already carries.
                    case let .reminderTapped(id):
                        guard state.editing?.id != id, let reminder = state.contents.rows.first(id: id) else { break }
                        let editing = state.editing
                        store.addTask(id: state.writes) {
                            try await commit(editing)
                            try store.modify {
                                $0.endEditing(editing?.session)
                                $0.editing = Reminders.Update.Feature.State(reminder, session: uuid())
                            }
                        }
                    }
                }
                ComposableArchitecture2.Scope(\.observing) { Observing(reminders.read) }
            }
            .calling(\.call, reminders, id: \.writes)
            .ifLet(\.editing) {
                Reminders.Update.Feature()
            }
            // Leaving writes the draft.
            .onDismount {
                try await commit(store.editing)
            }
        }
    }
}

extension Reminders.Read.Page.Feature {
    private func startNewReminder(in list: Models.List<Reminder>.ID, _ state: inout State) {
        let previous = state.editing
        store.addTask(id: state.writes) {
            try await commit(previous)
            let reminder = Reminder(id: Reminder.ID(uuid()), list: list, created: now)
            try await reminders.create(reminder)
            try store.modify {
                $0.endEditing(previous?.session)
                $0.editing = Reminders.Update.Feature.State(reminder, session: uuid())
            }
        }
    }

    private func endEditing(_ state: inout State) {
        guard let editing = state.editing else { return }
        store.addTask(id: state.writes) {
            try await commit(editing)
            try store.modify { $0.endEditing(editing.session) }
        }
    }

    // A draft is written whole when its session ends; a blank row is dropped; a row that is gone stays gone.
    private func commit(_ editing: Reminders.Update.Feature.State?) async throws {
        guard let editing else { return }
        if editing.isBlank {
            try await reminders.delete(editing.id)
        } else if !editing.isSaved {
            do {
                try await reminders.update(editing.request)
            } catch Reminders.Update.Error.notFound {}
        }
    }
}
