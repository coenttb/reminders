public import ComposableArchitecture2
public import Organizing
public import Reminder
public import Reminders
public import Tagged

extension Reminders.Feature {
    public enum TagDeleted: FeatureEventKey {
        public typealias Value = Tag<Reminder>.ID
    }
}
