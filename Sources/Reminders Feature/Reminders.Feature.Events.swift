public import ComposableArchitecture2
public import Models
public import Reminder
public import Reminders
public import Tagged

// Events travel from a screen up to the root: a failure to show, a sheet to open, a filter to close.
extension Reminders.Feature {
    public enum Failed: FeatureEventKey {
        public typealias Value = String
    }

    public enum ReminderDetailsRequested: FeatureEventKey {
        public typealias Value = Reminder
    }

    public enum ListDeleted: FeatureEventKey {
        public typealias Value = Models.List<Reminder>.ID
    }

    public enum TagDeleted: FeatureEventKey {
        public typealias Value = Tag<Reminder>
    }
}
