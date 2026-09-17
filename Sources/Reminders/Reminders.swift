public import Interface_Macro
public import Models
public import Reminder

@Interface
public struct Reminders: Reminders.Interface {
    public protocol Interface {
        func create(_ reminder: Reminder, below: Reminders.Placement?) throws -> Reminders.Placement
        func retrieve(_ id: Reminder.ID) throws -> Reminders.Placement
        func update(_ reminder: Reminder) throws -> Reminders.Placement
        func overview(today: Reminders.Day) throws -> Reminders.Summary

        var delete: Reminders.Delete { get }
        var filters: Reminders.Filters { get }
        var search: Reminders.Search { get }
        var lists: Reminders.Lists { get }
        var tags: Reminders.Tags { get }
    }
}

