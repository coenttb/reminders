public import Interface_Macro
public import Reminder

extension Reminders {
    // Reads: the summary is followed by the UI, so it is a stream (the value now, then again on every change); a
    // single reminder is read once, as a value; a page is its own interface. Over local storage a stream costs
    // one tracked query; over the network it is a subscription, so only what the UI genuinely follows is one.
    @Interface(.sendable)
    public struct Read: Read.Interface {
        public protocol Interface {
            func callAsFunction() -> AsyncThrowingStream<Reminders.Read.Value, any Swift.Error>
            func callAsFunction(_ id: Reminder.ID) throws -> Reminder
            var page: Reminders.Read.Page { get }
        }
    }
}
