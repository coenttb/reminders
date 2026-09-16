public import ComposableArchitecture2
import Dependencies
public import Reminders
public import Reminders_Feature

extension StoreOf<Reminders.Feature> {
    public static func live() -> StoreOf<Reminders.Feature> {
        prepareDependencies { try! $0.bootstrapDatabase() }
        return Store(initialState: State()) { Reminders.Feature() }
    }
}
