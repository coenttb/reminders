public import Foundation
public import Models
public import Reminder

extension Reminders.Editor {
    public enum Start {
        public typealias Result = Reminders.Placement?
        public typealias Client = Models.Operation<Request, Result>
    }
}

extension Reminders.Editor.Start {
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
