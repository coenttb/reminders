public import Foundation
public import Models
public import Reminder

extension Reminders {
    public struct Start: Sendable {
        public typealias Result = Reminders.Placement?
        public typealias Client = Models.Operation<Request, Result>

        public var client: Client

        public init(client: Client) {
            self.client = client
        }
    }
}

extension Reminders.Start {
    public struct Request: Hashable, Sendable {
        public var list: Models.List<Reminder>.ID
        public var below: Reminders.Placement?
        public var created: Date

        public init(list: Models.List<Reminder>.ID, below: Reminders.Placement?, created: Date) {
            self.list = list
            self.below = below
            self.created = created
        }
    }
}
