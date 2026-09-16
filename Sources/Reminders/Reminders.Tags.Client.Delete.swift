public import Models
public import Reminder

extension Reminders.Tags.Client {
    public struct Delete: Operation {
        public typealias Request = Tag<Reminder>
        public typealias Result = Void

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}
