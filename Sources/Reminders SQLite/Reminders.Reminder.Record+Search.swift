public import Foundation
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SQLiteData

extension Reminders.Reminder.Record {
    public static func deleteCompleted(matching search: Reminders.Search, dueBefore cutoff: Date?) -> DeleteOf<Reminder.Record> {
        Reminder.Record
            .where { $0.isDone && $0.matches(search) }
            .where { if let cutoff { $0.dueDate.lt(Date?.some(cutoff)) } }
            .delete()
    }
}
