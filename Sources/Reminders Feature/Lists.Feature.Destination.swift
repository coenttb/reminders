public import ComposableArchitecture2
public import Reminders

extension Lists.Feature {
    /// The one sheet the home can present: a reminder form or a list form.
    @ComposableArchitecture2.Feature public enum Destination {
        case list(Reminder.List.Feature)
        case reminder(Reminder.Feature)
    }
}

// The macro-generated state carries only `Sendable` drafts; `Lists.Feature.State` is `Sendable`.
extension Lists.Feature.Destination.State: Sendable {}
extension Lists.Feature.Destination.State.DebugSnapshot: Sendable {}
