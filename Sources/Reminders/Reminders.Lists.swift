public import Interface_Macro

extension Reminders {
    @Interface
    public struct Lists: Lists.Interface {
        @Operations
        public protocol Interface {
            var create: Reminders.Lists.Create { get }
            var delete: Reminders.Lists.Delete { get }
        }
    }
}
