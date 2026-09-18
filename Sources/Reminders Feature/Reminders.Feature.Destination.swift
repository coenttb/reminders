public import ComposableArchitecture2
public import Dependencies
public import Interface_ComposableArchitecture
public import Reminders
public import Reminders_Dependency

extension Reminders.Feature {
    @ComposableArchitecture2.Feature public enum Destination {
        // The sheet: `lists.create`'s request being composed, sent to whichever `reminders` is current.
        case list(
            Requesting<Reminders.Lists.Operations.Create> = Requesting {
                try await Dependency(\.reminders).wrappedValue.lists.create($0)
            }
        )
    }
}
