public import ComposableArchitecture2
public import Reminders

// Events travel from a screen up to the root.
extension Reminders.Feature {
    public enum Failed: FeatureEventKey {
        public typealias Value = String
    }
}
