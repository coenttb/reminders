public import Foundation
public import Interface_Macro
public import Models
public import Reminder

@Interface
public struct Reminders: Reminders.Interface {
    public protocol Interface {
        func create(_ reminder: Reminder, below: Reminders.Placement?) throws -> Reminders.Placement
        func retrieve(_ id: Reminder.ID) throws -> Reminders.Placement
        func update(_ reminder: Reminder) throws -> Reminders.Placement
        func delete(_ id: Reminder.ID) throws
        func list(_ selection: Reminders.Selection, today: Range<Date>, including: Reminders.Placement?, limit: Int?) throws -> Reminders.Page
        func reorder(_ ids: [Reminder.ID], in filter: Reminders.Filter) throws
        func complete(_ id: Reminder.ID) throws
        func reopen(_ id: Reminder.ID) throws
        func deleteCompleted(_ completed: Reminders.Completed) throws
        func overview(today: Range<Date>) throws -> Reminders.Summary

        var lists: Reminders.Lists { get }
        var tags: Reminders.Tags { get }
        var preferences: Reminders.Preferences { get }
    }
}

extension Reminders: @unchecked Sendable {}
