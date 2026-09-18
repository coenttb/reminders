public import Interface_Macro
public import Reminder

extension Reminders.Read {
    // One page of reminders, followed: the rows matching a filter, now and after every change.
    @Interface
    public struct Page: Page.Interface {
        @Operations
        public protocol Interface {
            func callAsFunction(filter: Reminders.Read.Filter) -> AsyncThrowingStream<Reminders.Read.Page.Value, any Swift.Error>
        }
    }
}
