public import Foundation
public import Models
public import Reminder

extension Reminders.Editor {
    public struct Client: Sendable {
        public var reminder: @Sendable (Reminder.ID) throws -> Reminders.Placement?
        public var start: @Sendable (_ list: List<Reminder>.ID, _ below: Reminders.Placement?, _ created: Date) throws -> Reminders.Placement?
        public var add: @Sendable (Reminder) throws -> Bool
        public var update: @Sendable (Reminder) throws -> Bool
        public var toggle: @Sendable (Reminder.ID) throws -> Bool?
        public var delete: @Sendable (Reminder.ID) throws -> Void
        public var move: @Sendable ([Reminder.ID], _ filter: Reminders.Filter) throws -> Void
        public var deleteCompleted: @Sendable (Reminders.Selection, _ today: Range<Date>, _ dueBefore: Date?) throws -> Void

        public init(
            reminder: @escaping @Sendable (Reminder.ID) throws -> Reminders.Placement?,
            start: @escaping @Sendable (_ list: List<Reminder>.ID, _ below: Reminders.Placement?, _ created: Date) throws -> Reminders.Placement?,
            add: @escaping @Sendable (Reminder) throws -> Bool,
            update: @escaping @Sendable (Reminder) throws -> Bool,
            toggle: @escaping @Sendable (Reminder.ID) throws -> Bool?,
            delete: @escaping @Sendable (Reminder.ID) throws -> Void,
            move: @escaping @Sendable ([Reminder.ID], _ filter: Reminders.Filter) throws -> Void,
            deleteCompleted: @escaping @Sendable (Reminders.Selection, _ today: Range<Date>, _ dueBefore: Date?) throws -> Void
        ) {
            self.reminder = reminder
            self.start = start
            self.add = add
            self.update = update
            self.toggle = toggle
            self.delete = delete
            self.move = move
            self.deleteCompleted = deleteCompleted
        }
    }
}
