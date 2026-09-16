import Foundation
public import Organizing
public import Reminders
import SQLiteData
public import Tagged

extension Reminder {
    public init(_ record: Reminder.Record, tags: Set<Tag<Reminder>.ID>) {
        self.init(
            id: record.id,
            list: record.listID,
            title: record.title,
            notes: record.notes,
            due: record.due.map { Reminder.Due($0, hasTime: record.hasTime) },
            flagged: record.flagged,
            priority: record.priority.flatMap(Reminder.Priority.init(rawValue:)),
            completion: Reminder.Record.completion(record.status),
            tags: tags,
            position: record.position,
            location: record.location.flatMap(Reminder.Location.init(rawValue:)),
            repeats: Reminder.Repeat(rawValue: record.repeats) ?? .never,
            created: record.created
        )
    }
}
