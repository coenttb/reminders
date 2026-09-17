public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Reminder
public import Reminders
public import Tagged

extension Reminders {
    struct Completion<State: Gracing, Action> {
        static var grace: Duration { .seconds(5) }

        let store: FeatureStore<State, Action>
        let reminders: Reminders
        let clock: any Clock<Duration>
        let uuid: Dependencies.UUIDGenerator
    }
}

extension Reminders.Completion {
    func tapped(_ id: Reminder.ID, _ state: inout State) {
        if state.grace.removeValue(forKey: id) != nil { return }
        if state.isCompleted(id) == true {
            store.addTask { try await finish(id, completed: false) }
        } else {
            let token = uuid()
            state.grace[id] = token
            store.addTask {
                try await clock.sleep(for: Self.grace)
                guard store.grace[id] == token else { return }
                try await finish(id, completed: true)
            }
        }
    }

    func finishAll(_ state: inout State) {
        for id in state.grace.keys {
            store.addTask { try await finish(id, completed: true) }
        }
        state.grace = [:]
    }

    func finish(_ id: Reminder.ID, completed: Bool) async throws {
        try await store.attempt {
            try await complete(id, completed)
            try store.modify {
                $0.grace.removeValue(forKey: id)
                $0.finished(id, completed: completed)
            }
        }
    }

    // Leaving writes what is still in grace, on the spot.
    func finish(_ ids: some Sequence<Reminder.ID>) async throws {
        for id in ids { try await complete(id, true) }
    }

    func retrieve(_ id: Reminder.ID) throws -> Reminders.Placement? {
        do {
            return try reminders.read(id)
        } catch Reminders.Read.Error.notFound {
            return nil
        }
    }

    private func complete(_ id: Reminder.ID, _ completed: Bool) async throws {
        guard var reminder = try retrieve(id)?.reminder, reminder.completed != completed else { return }
        reminder.completed = completed
        _ = try await reminders.update(reminder)
    }
}
