public import ComposableArchitecture2
import Dependencies
public import Reminders
public import Reminders_Feature

extension Store where State == Reminder.Feature.State, Action == Reminder.Feature.Action {
    public static func live() -> StoreOf<Reminder.Feature> {
        prepareDependencies { try! $0.bootstrapDatabase() }
        return Store(initialState: State()) { Reminder.Feature() }
    }
}
