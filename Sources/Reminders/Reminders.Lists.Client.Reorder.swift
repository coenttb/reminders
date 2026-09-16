public import Models
public import Reminder

extension Reminders.Lists.Client {
    public struct Reorder: Operation {
        public typealias Request = [List<Reminder>.ID]
        public typealias Result = Void

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}
