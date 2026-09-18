public import Interface_Macro

extension Reminders {
    // A read's request is an address; observing it yields the value now and again on every change.
    // The features observe; the storage decides how (SQLite tracks the query).
    @Interface
    public struct Observe: Observe.Interface {
        public protocol Interface {
            func callAsFunction(_ summary: Reminders.Read.Request) -> AsyncThrowingStream<Reminders.Summary, any Swift.Error>
            func callAsFunction(_ page: Reminders.Read.Page.Request) -> AsyncThrowingStream<Reminders.Page, any Swift.Error>
        }
    }
}
