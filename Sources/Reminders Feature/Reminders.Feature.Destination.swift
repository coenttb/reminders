public import ComposableArchitecture2
public import Reminders

extension Reminders.Feature {
    @ComposableArchitecture2.Feature public enum Destination {
        case list(Reminders.Lists.Create.Feature)
    }
}
