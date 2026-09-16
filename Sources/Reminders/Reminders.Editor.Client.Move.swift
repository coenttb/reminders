public import Models
public import Reminder

extension Reminders.Editor.Client {
    public struct Move: Operation {
        public typealias Result = Void

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Editor.Client.Move {
    public struct Request: Hashable, Sendable {
        public var ids: [Reminder.ID]
        public var filter: Reminders.Filter

        public init(ids: [Reminder.ID], filter: Reminders.Filter) {
            self.ids = ids
            self.filter = filter
        }
    }
}
