public import Models

extension Reminders.Preferences {
    public enum ToggleShowCompleted {
        public typealias Request = Reminders.Filter
        public typealias Result = Void
        public typealias Client = Operation<Request, Result>
    }
}
