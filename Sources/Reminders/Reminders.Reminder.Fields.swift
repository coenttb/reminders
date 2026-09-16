public import Foundation

extension Reminders.Reminder {
    public protocol Fields {
        var title: String { get }
        var dueDate: Date? { get set }
        var hasTime: Bool { get set }
        var flagged: Bool { get set }
        var priority: Reminders.Reminder.Priority? { get set }
        var completed: Bool { get }
    }
}
