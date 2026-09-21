public import Interface_Macro

// The domain, declared once: every operation is a method signature on a protocol, and the macro derives
// the value the app calls and the closures the storage fills in.
@Interface
public struct Reminders: Reminders.Interface {
    public protocol Interface {
        var create: Reminders.Create { get }
        var read: Reminders.Read { get }
        var update: Reminders.Update { get }
        var delete: Reminders.Delete { get }
        var lists: Reminders.Lists { get }
    }
}
