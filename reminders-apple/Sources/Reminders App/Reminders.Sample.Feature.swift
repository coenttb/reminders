#if DEBUG
public import ComposableArchitecture2
import Dependencies
import Foundation
import Models
import Reminder
public import Reminders
public import Reminders_Sample
import Reminders_Feature
import Reminders_SQL
import Reminders_SQLite
import Sharing
import SQLiteData
import Tagged

extension Reminders.Sample {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Sample.Feature

            public var lastSeed: Reminders.Sample.Seed?
            public var isSeeding = false
            public var failure: String?

            public init() {}
        }

        public enum Action {
            case seedButtonTapped
            case seedGenerated(Reminders.Sample.Scale, seed: UInt64?)
            case deleteEverythingButtonTapped
            case failureDismissed
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.uuid) var uuid
        @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
        // A replaced database has no row to restore.
        @Shared(.appStorage(Reminders.Feature.editingKey)) var editingID: String?

        let replaced: () -> Void

        public init(replaced: @escaping () -> Void) {
            self.replaced = replaced
        }

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .seedButtonTapped:
                    let sample = Reminders.sample(at: now)
                    state.isSeeding = true
                    store.addTask {
                        try await attempt {
                            try write { db in
                                try sample.replace(in: db)
                            }
                            $editingID.withLock { $0 = nil }
                            replaced()
                        }
                    }
                case let .seedGenerated(scale, seed):
                    let value = seed ?? withRandomNumberGenerator { UInt64.random(in: .min ... .max, using: &$0) }
                    state.lastSeed = Reminders.Sample.Seed(scale: scale, value: value)
                    state.isSeeding = true
                    store.addTask {
                        try await attempt {
                            let sample = Reminders.Sample.generated(scale, seed: value, at: now, calendar: calendar)
                            try await database.write { db in
                                try sample.replace(in: db)
                            }
                            $editingID.withLock { $0 = nil }
                            replaced()
                        }
                    }
                case .deleteEverythingButtonTapped:
                    let replacement = List<Reminder>.ID(uuid())
                    state.isSeeding = true
                    store.addTask {
                        try await attempt {
                            try write { db in
                                try Reminders.Sample(lists: []).replace(in: db)
                                try List<Reminder>.Record.installDefault(replacement, in: db)
                            }
                            $editingID.withLock { $0 = nil }
                            replaced()
                        }
                    }
                case .failureDismissed:
                    state.failure = nil
                }
            }
        }
    }
}

extension Reminders.Sample.Feature {
    private func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }

    private func attempt(_ body: () async throws -> Void) async throws {
        do {
            try await body()
            try store.modify { $0.isSeeding = false }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify {
                $0.isSeeding = false
                $0.failure = error.localizedDescription
            }
        }
    }
}
#endif
