import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminders.Search.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Search.Contents {
        var contents = Reminders.Search.Contents()
        guard search.matchesReminders || search.tagPrefix != nil else { return contents }
        if let prefix = search.tagPrefix {
            let taken = search.tags.map(\.rawValue)
            contents.suggestions = try Tag<Reminder>.Record
                .where { $hasCaseInsensitivePrefix($0.title, prefix) && !$0.title.in(taken) }
                .order { $0.title.collate($localizedCaseInsensitive) }
                .fetchAll(db)
        }
        let (matched, completed) = try Reminder.Record
            .where { $0.matches(search) }
            .select { ($0.id.count(), $0.isDone.cast(as: Int.self).sum() ?? 0) }
            .fetchOne(db) ?? (0, 0)
        contents.completedCount = completed
        contents.total = search.showCompleted ? matched : matched - completed
        let matches = try Reminder.Record
            .where { $0.matches(search) }
            .where { if !search.showCompleted { !$0.isDone } }
            .join(List<Reminder>.Record.all) { $0.listID.eq($1.id) }
            .order { reminders, lists in
                (lists.position, reminders.isDone, reminders.ordered(by: .dueDate, showCompleted: false))
            }
            .limit(limit ?? contents.total)
            .select { Reminder.Record.Match.Columns(reminder: $0, tags: $0.tags, list: $1) }
            .fetchAll(db)
        for match in matches {
            let row = Reminder.Record.Row(reminder: match.reminder, tags: match.tags)
            if contents.sections.last?.list.id == match.list.id {
                contents.sections[contents.sections.count - 1].rows.append(row)
            } else {
                contents.sections.append(Reminders.Search.Contents.Section(list: match.list, rows: [row]))
            }
        }
        return contents
    }
}
