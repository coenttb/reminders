public import ComposableArchitecture2
public import Organizing
public import Reminders

extension Reminder.Feature {
    @ComposableArchitecture2.Feature public enum Destination {
        case list(List<Reminder>.Draft.Feature)
        case reminder(Reminder.Draft.Feature)
    }
}

extension Reminder.Feature.Destination.State: Sendable {}
extension Reminder.Feature.Destination.State.DebugSnapshot: Sendable {}
