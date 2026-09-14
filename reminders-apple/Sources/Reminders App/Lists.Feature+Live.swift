public import ComposableArchitecture2
import Dependencies
public import Reminders
public import Reminders_Feature

extension Lists.Feature {
    /// Bootstraps the application's database and returns the store the host owns.
    public static func live() -> StoreOf<Lists.Feature> {
        prepareDependencies { try! $0.bootstrapDatabase() }
        return Store(initialState: State()) { Lists.Feature() }
    }
}
