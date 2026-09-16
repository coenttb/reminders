public import Models
public import Reminder

extension Reminders.Tags.Client {
    public struct Add: Operation {
        public typealias Request = String
        public typealias Result = Tag<Reminder>?

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}
