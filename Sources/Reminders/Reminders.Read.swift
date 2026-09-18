public import Interface_Macro
public import Reminder

extension Reminders {
    // One interface, two forms: the summary and a page are followed by the UI, so they are streams (the
    // value now, then again on every change); a single reminder is read once, as a value. Over local
    // storage a stream costs one tracked query; over the network it is a subscription, so only what
    // the UI genuinely follows is declared as one.
    @Interface
    public struct Read: Read.Interface {
        public protocol Interface {
            func callAsFunction() -> AsyncThrowingStream<Reminders.Read.Summary, any Swift.Error>
            func callAsFunction(_ id: Reminder.ID) throws -> Reminder
            func callAsFunction(page filter: Reminders.Read.Filter) -> AsyncThrowingStream<Reminders.Page, any Swift.Error>
        }
    }
}
