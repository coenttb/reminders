public import ComposableArchitecture2
public import Organizing
public import Reminders

extension Reminders.Feature {
    @ComposableArchitecture2.Feature public enum Destination {
        case list(List<Reminder>.Draft.Feature)
        case reminder(Reminder.Draft.Feature)
    }
}

extension Reminders.Feature.Destination.State: Sendable {}
extension Reminders.Feature.Destination.State.DebugSnapshot: Sendable {}
