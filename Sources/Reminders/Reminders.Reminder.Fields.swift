public import Foundation

extension Reminders.Reminder {
    /// The fields the rules read and write, so a rule is stated once for the wire shape, the
    /// record, and the record's draft.
    public protocol Fields {
        var title: String { get }
        var dueDate: Date? { get set }
        var hasTime: Bool { get set }
        var flagged: Bool { get set }
        var priority: Reminders.Reminder.Priority? { get set }
        var completed: Bool { get }
    }
}
