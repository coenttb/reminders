public import Interface_Macro

extension Reminders {
    @Interface(.sendable)
    public struct Lists: Lists.Interface {
        public protocol Interface {
            var create: Reminders.Lists.Create { get }
            var delete: Reminders.Lists.Delete { get }
        }
    }
}
