public import Interface_Macro

@Interface
public struct Reminders: Reminders.Interface {
    public protocol Interface {
        var create: Reminders.Create { get }
        var read: Reminders.Read { get }
        var update: Reminders.Update { get }
        var delete: Reminders.Delete { get }
        var lists: Reminders.Lists { get }
        var tags: Reminders.Tags { get }
    }
}

