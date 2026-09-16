public import Models

extension Reminders.Preferences.Client {
    public struct ToggleShowCompleted: Operation {
        public typealias Request = Reminders.Filter
        public typealias Result = Void

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}
