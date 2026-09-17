public import Interface_Macro
public import Models
public import Reminder

@Interface
public struct Reminders: Reminders.`Protocol` {
    public protocol `Protocol` {
        associatedtype Lists: Reminders.Lists.`Protocol`
        associatedtype Tags: Reminders.Tags.`Protocol`
        associatedtype Preferences: Reminders.Preferences.`Protocol`

        func create(_ request: Reminders.Create.Request) throws -> Reminders.Placement
        func retrieve(_ id: Reminder::Reminder.ID) throws -> Reminders.Placement
        func update(_ reminder: Reminder::Reminder) throws -> Reminders.Placement
        func delete(_ id: Reminder::Reminder.ID) throws
        func list(_ request: Reminders.List.Request) throws -> Reminders.List.Result
        func reorder(_ request: Reminders.Reorder.Request) throws
        func complete(_ id: Reminder::Reminder.ID) throws
        func reopen(_ id: Reminder::Reminder.ID) throws
        func deleteCompleted(_ request: Reminders.DeleteCompleted.Request) throws
        func overview(_ request: Reminders.Overview.Request) throws -> Reminders.Overview.Result

        var lists: Lists { get }
        var tags: Tags { get }
        var preferences: Preferences { get }
    }
}

extension Reminders: @unchecked Sendable {}
