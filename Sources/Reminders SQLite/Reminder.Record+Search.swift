public import Foundation
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData

extension Reminder.Record {
    public static func deleteCompleted(in filter: Reminders.Filter, today: Range<Date>) -> DeleteOf<Reminder.Record> {
        Reminder.Record
            .where { $0.isCompleted && $0.belongs(to: filter, today: today) }
            .delete()
    }

    public static func deleteCompleted(matching query: Reminders.Search.Query, dueBefore cutoff: Date?) -> DeleteOf<Reminder.Record> {
        Reminder.Record
            .where { $0.isCompleted && $0.matches(query) }
            .where { if let cutoff { $0.dueDate.lt(Date?.some(cutoff)) } }
            .delete()
    }
}
