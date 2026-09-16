public import ComposableArchitecture2
public import Models
public import Reminder
public import Reminders
public import Reminders_Interface

extension Reminders.Feature {
    @ComposableArchitecture2.Feature public enum Destination {
        case list(List<Reminder>.Form.Feature)
        case reminder(Reminder.Form.Feature)
    }
}

extension Reminders.Feature.Destination.State: Sendable {}
extension Reminders.Feature.Destination.State.DebugSnapshot: Sendable {}
