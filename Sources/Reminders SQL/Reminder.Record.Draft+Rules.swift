public import Foundation
public import Reminder
import Reminders

extension Reminder.Record.Draft {
    public var completed: Bool { status != .incomplete }

    public var isBlank: Bool { Reminder.isBlank(title: title) }

    public mutating func set(due date: Date?) { due = Reminder.Due.setting(due, date: date) }
}
