public import Models
public import Reminder

extension Reminders.Editor.Client {
    public struct Delete: Operation {
        public typealias Request = Reminder.ID
        public typealias Result = Void

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}
