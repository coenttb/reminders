import Foundation
import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Search.Results.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminder.Search.Results {
        var results = Reminder.Search.Results()
        guard search.matchesReminders || search.tagPrefix != nil else { return results }
        if let prefix = search.tagPrefix {
            let taken = search.tags.map(\.rawValue)
            results.suggestions = try Tag<Reminder>.Record
                .where { $hasCaseInsensitivePrefix($0.title, prefix) && !$0.title.in(taken) }
                .order { $0.title.collate($localizedCaseInsensitive) }
                .fetchAll(db)
                .map(Tag<Reminder>.init)
        }
        let (matched, completed) = try Reminder.Record
            .where { $0.matches(search) }
            .select { ($0.id.count(), $0.isDone.cast(as: Int.self).sum() ?? 0) }
            .fetchOne(db) ?? (0, 0)
        results.completedCount = completed
        results.total = search.showCompleted ? matched : matched - completed
        let rows = try Reminder.Record
            .where { $0.matches(search) }
            .where { if !search.showCompleted { !$0.isDone } }
            .join(List<Reminder>.Record.all) { $0.listID.eq($1.id) }
            .order { reminders, lists in
                (lists.position, reminders.isDone, reminders.ordered(by: .dueDate, showCompleted: false))
            }
            .limit(limit ?? results.total)
            .select { Match.Columns(reminder: $0, tags: $0.tagList, list: $1) }
            .fetchAll(db)
        for row in rows {
            if results.sections.last?.list.id == row.list.id {
                results.sections[results.sections.count - 1].reminders.append(Reminder(row))
            } else {
                results.sections.append(Reminder.Search.Results.Section(list: List(row.list), reminders: [Reminder(row)]))
            }
        }
        return results
    }
}
