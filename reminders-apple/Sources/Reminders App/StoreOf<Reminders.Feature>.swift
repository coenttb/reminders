public import ComposableArchitecture2
import Dependencies
public import Reminders
public import Reminders_Feature
import Reminders_SQLite
#if DEBUG
import Reminders_Sample
#endif

extension StoreOf<Reminders.Feature> {
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
