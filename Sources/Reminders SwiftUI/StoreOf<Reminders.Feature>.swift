public import ComposableArchitecture2
import Dependencies
public import Reminders
public import Reminders_Feature
import Reminders_Sample
import Reminders_SQLite

extension StoreOf<Reminders.Feature> {
    // The live store: the database is opened and bound to the domain before the first feature reads it.
    public static func live() -> StoreOf<Reminders.Feature> {
        prepareDependencies {
            #if DEBUG
            try! $0.bootstrapDatabase(seeding: Reminders.sample(at: $0.date.now))
            #else
            try! $0.bootstrapDatabase()
            #endif
        }
        return Store(initialState: State()) { Reminders.Feature() }
    }
}
