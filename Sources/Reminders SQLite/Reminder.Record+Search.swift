public import Foundation
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record {
    public static func deleteCompleted(in selection: Reminders.Selection, today: Range<Date>, dueBefore cutoff: Date?) -> DeleteOf<Reminder.Record> {
        Reminder.Record
            .where { $0.isCompleted && $0.selected(by: selection, today: today) }
            .where { if let cutoff { $0.dueDate.lt(Date?.some(cutoff)) } }
            .delete()
    }
}
