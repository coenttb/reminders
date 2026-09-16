public import Foundation
public import Models
public import Reminder

extension Reminders.Editor.Client {
    public struct Start: Models.Operation {
        public typealias Result = Reminders.Placement?

        public var run: @Sendable (Request) throws -> Result

        public init(_ run: @escaping @Sendable (Request) throws -> Result) {
            self.run = run
        }
    }
}

extension Reminders.Editor.Client.Start {
    public struct Request: Hashable, Sendable {
        public var list: List<Reminder>.ID
        public var below: Reminders.Placement?
        public var created: Date

        public init(list: List<Reminder>.ID, below: Reminders.Placement?, created: Date) {
            self.list = list
            self.below = below
            self.created = created
        }
    }
}
