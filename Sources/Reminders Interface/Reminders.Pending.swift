public import Reminders

extension Reminders {
    /// The grace period between the tap on a reminder and its completion.
    public enum Pending {
        public static let grace: Duration = .seconds(5)
    }
}
