public import Models
public import Reminder

extension Reminders.Lists.Client {
    public struct Update: Operation {
        public typealias Request = List<Reminder>
        public typealias Result = Bool

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}
