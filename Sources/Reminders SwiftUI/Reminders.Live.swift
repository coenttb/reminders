public import ComposableArchitecture2
import Dependencies
public import Reminders
public import Reminders_Feature
import Reminders_Dependency
import Reminders_Sample
import Reminders_SQLite

extension StoreOf<Reminders> {
    // The live store: the database is opened and bound to the domain before the first feature reads it.
    public static func live() -> StoreOf<Reminders> {
        prepareDependencies {
            #if DEBUG
            try! $0.bootstrapDatabase(seeding: Reminders.sample(at: $0.date.now))
            #else
            try! $0.bootstrapDatabase()
            #endif
        }
        @Dependency(\.reminders) var reminders
        return Store(initialState: .init()) { reminders }
    }
}
