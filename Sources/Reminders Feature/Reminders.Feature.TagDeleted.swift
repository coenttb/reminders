public import ComposableArchitecture2
public import Models
public import Reminder
public import Reminders
import Tagged

extension Reminders.Feature {
    public enum TagDeleted: FeatureEventKey {
        public typealias Value = Tag<Reminder>
    }
}
