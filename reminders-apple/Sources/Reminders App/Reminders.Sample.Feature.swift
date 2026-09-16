#if DEBUG
import ComposableArchitecture2
import Dependencies
import Organizing
import Reminders
import Reminders_Sample
import Reminders_SQL
import Reminders_SQLite
import SQLiteData
import Tagged

extension Reminders.Sample {
    @ComposableArchitecture2.Feature struct Feature {
        struct State: Sendable {
            typealias Feature = Reminders.Sample.Feature

            var lastSeed: Reminders.Sample.Seed?
            var isSeeding = false

            init() {}
        }

        enum Action {
            case seedButtonTapped
            case seedGenerated(Reminders.Sample.Scale, seed: UInt64?)
            case deleteEverythingButtonTapped
        }

        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.uuid) var uuid
        @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator

        let replaced: () -> Void

        init(replaced: @escaping () -> Void) {
            self.replaced = replaced
        }

        var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .seedButtonTapped:
                    let sample = Reminders.sample(at: now)
                    store.addTask {
                        try write { db in
                            try sample.replace(in: db)
                            try Reminders.Restoration.set(editing: nil).execute(db)
                        }
                        replaced()
                    }
                case let .seedGenerated(scale, seed):
                    let value = seed ?? withRandomNumberGenerator { UInt64.random(in: .min ... .max, using: &$0) }
                    state.lastSeed = Reminders.Sample.Seed(scale: scale, value: value)
                    state.isSeeding = true
                    store.addTask {
                        let sample = Reminders.Sample.generated(scale, seed: value, at: now, calendar: calendar)
                        try await database.write { db in
                            try sample.replace(in: db)
                            try Reminders.Restoration.set(editing: nil).execute(db)
                        }
                        replaced()
                        try store.modify { $0.isSeeding = false }
                    }
                case .deleteEverythingButtonTapped:
                    let replacement = List<Reminder>.ID(uuid())
                    store.addTask {
                        try write { db in
                            try Reminders.Sample(lists: []).replace(in: db)
                            try List<Reminder>.Record.installDefault(replacement, in: db)
                            try Reminders.Restoration.set(editing: nil).execute(db)
                        }
                        replaced()
                    }
                }
            }
        }
    }
}

extension Reminders.Sample.Feature {
    private func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }
}
#endif
