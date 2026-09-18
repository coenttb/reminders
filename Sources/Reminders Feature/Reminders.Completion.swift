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
        let now: Dependencies.DateGenerator
        let uuid: Dependencies.UUIDGenerator
    }
}

extension Reminders.Completion {
    // A tap restarts the one completion task: tasks of the same action replace each other, so the
    // state carries what is pending and the task works through it — reopenings at once, the rows in
    // grace once the grace period has passed since the last tap.
    func tapped(_ id: Reminder.ID, _ state: inout State) {
        if state.grace.removeValue(forKey: id) != nil { return }
        if state.isCompleted(id) == true {
            state.reopening.insert(id)
        } else {
            state.grace[id] = uuid()
        }
        store.addTask {
            for id in store.reopening where store.reopening.contains(id) { try await finish(id, completed: false) }
            guard !store.grace.isEmpty else { return }
            try await clock.sleep(for: Self.grace)
            for id in store.grace.keys where store.grace[id] != nil { try await finish(id, completed: true) }
        }
    }

    func finishAll(_ state: inout State) {
        for id in state.grace.keys {
            store.addTask { try await finish(id, completed: true) }
        }
        state.grace = [:]
    }

    // Completing stamps the moment; reopening clears it.
    func finish(_ id: Reminder.ID, completed: Bool) async throws {
        try await store.attempt {
            let completed = try await complete(id, completed)
            try store.modify {
                $0.grace.removeValue(forKey: id)
                $0.reopening.remove(id)
                $0.finished(id, completed: completed)
            }
        }
    }

    // Leaving writes what is still in grace, on the spot.
    func finish(_ ids: some Sequence<Reminder.ID>) async throws {
        for id in ids { _ = try await complete(id, true) }
    }

    func retrieve(_ id: Reminder.ID) throws -> Reminders.Placement? {
        do {
            return try reminders.read(id)
        } catch Reminders.Read.Error.notFound {
            return nil
        }
    }

    @discardableResult
    private func complete(_ id: Reminder.ID, _ completed: Bool) async throws -> Date? {
        guard var reminder = try retrieve(id)?.reminder else { return nil }
        guard reminder.isCompleted != completed else { return reminder.completed }
        reminder.completed = completed ? now() : nil
        _ = try await reminders.update(reminder)
        return reminder.completed
    }
}
