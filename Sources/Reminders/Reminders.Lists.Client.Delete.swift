public import Models
public import Reminder

extension Reminders.Lists.Client {
    public struct Delete: Operation {
        public typealias Result = Void

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Lists.Client.Delete {
    public struct Request: Hashable, Sendable {
        public var id: List<Reminder>.ID
        public var replacement: List<Reminder>.ID

        public init(id: List<Reminder>.ID, replacement: List<Reminder>.ID) {
            self.id = id
            self.replacement = replacement
        }
    }
}
