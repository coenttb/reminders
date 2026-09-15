public import ComposableArchitecture2
public import Organizing
public import Reminders

extension Reminder.Feature {
    /// The one sheet the home can present: a reminder form or a list form.
    @ComposableArchitecture2.Feature public enum Destination {
        case list(List<Reminder>.Draft.Feature)
        case reminder(Reminder.Draft.Feature)
    }
}

// The macro-generated state carries only `Sendable` drafts; `Reminder.Feature.State` is `Sendable`.
extension Reminder.Feature.Destination.State: Sendable {}
extension Reminder.Feature.Destination.State.DebugSnapshot: Sendable {}
