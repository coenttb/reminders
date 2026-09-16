public import ComposableArchitecture2
public import Organizing
public import Reminders
public import Tagged

extension Reminders.Feature {
    /// Posted by a form when it deletes a tag, so the screen showing that tag can close it.
    public enum TagDeleted: FeatureEventKey {
        public typealias Value = Tag<Reminder>.ID
    }
}
