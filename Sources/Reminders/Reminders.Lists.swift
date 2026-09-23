public import Interface_Macro

extension Reminders {
    @Interface
    public struct Lists: Lists.Interface, Sendable {
        public protocol Interface {
            var create: Reminders.Lists.Create { get }
            var update: Reminders.Lists.Update { get }
            var delete: Reminders.Lists.Delete { get }
        }
    }
}
