import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Search.Results {
    public struct Request: FetchKeyRequest {
        public var search: Reminder.Search
        public var limit: Int?

        public init(search: Reminder.Search, limit: Int? = nil) {
            self.search = search
            self.limit = limit
        }

        public func fetch(_ db: Database) throws -> Reminder.Search.Results {
            var results = Reminder.Search.Results()
            guard search.matchesReminders || search.tagPrefix != nil else { return results }
            if let prefix = search.tagPrefix {
                let taken = search.tags.map(\.rawValue)
                results.suggestions = try Tag<Reminder>.Record
                    .where { $hasCaseInsensitivePrefix($0.title, prefix) && !$0.title.in(taken) }
                    .order { $0.title.collate($localizedCaseInsensitive) }
                    .fetchAll(db)
                    .map(\.tag)
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
                    results.sections[results.sections.count - 1].reminders.append(row.value)
                } else {
                    results.sections.append(Reminder.Search.Results.Section(list: row.list.list, reminders: [row.value]))
                }
            }
            return results
        }

        @Selection
        fileprivate struct Match {
            let reminder: Reminder.Record
            let tags: String?
            let list: List<Reminder>.Record

            var value: Reminder { reminder.reminder(tags: Reminder.Record.tags(from: tags)) }
        }
    }
}
