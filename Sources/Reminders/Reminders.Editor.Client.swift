public import Foundation
public import Models
public import Reminder
public import Tagged

extension Reminders.Editor {
    public struct Client: Sendable {
        public var reminder: @Sendable (Reminder.ID) async throws -> Reminders.Placement?
        public var start: @Sendable (_ list: List<Reminder>.ID, _ anchor: Reminders.Placement?, _ created: Date) async throws -> Reminders.Placement?
        public var save: @Sendable (Reminder, _ isNew: Bool) async throws -> Bool
        public var toggle: @Sendable (Reminder.ID) async throws -> Bool?
        public var delete: @Sendable (Reminder.ID) async throws -> Void

        public init(
            reminder: @escaping @Sendable (Reminder.ID) async throws -> Reminders.Placement?,
            start: @escaping @Sendable (_ list: List<Reminder>.ID, _ anchor: Reminders.Placement?, _ created: Date) async throws -> Reminders.Placement?,
            save: @escaping @Sendable (Reminder, _ isNew: Bool) async throws -> Bool,
            toggle: @escaping @Sendable (Reminder.ID) async throws -> Bool?,
            delete: @escaping @Sendable (Reminder.ID) async throws -> Void
        ) {
            self.reminder = reminder
            self.start = start
            self.save = save
            self.toggle = toggle
            self.delete = delete
        }
    }
}
