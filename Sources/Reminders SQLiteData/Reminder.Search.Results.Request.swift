import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Search.Results {
    /// Reads the search in one transaction: the matches under their lists, how many of them are
    /// completed whether or not they are shown, and the tags completing a typed prefix.
    public struct Request: FetchKeyRequest {
        public var search: Reminder.Search

        public init(search: Reminder.Search) {
            self.search = search
        }

        public func fetch(_ db: Database) throws -> Reminder.Search.Results {
            var results = Reminder.Search.Results()
            // Nothing typed reads nothing: an idle search is not re-read on every write.
            guard search.matchesReminders || search.tagPrefix != nil else { return results }
            if let prefix = search.tagPrefix {
                let taken = search.tags.map(\.rawValue)
                results.suggestions = try Tag<Reminder>.Record
                    .where { $hasCaseInsensitivePrefix($0.title, prefix) && !$0.title.in(taken) }
                    .order { $0.title.collate($localizedCaseInsensitive) }
                    .fetchAll(db)
                    .map(\.tag)
            }
            results.completedCount = try Reminder.Record.where { $0.isDone && $0.matches(search) }.fetchCount(db)
            let rows = try Reminder.Record
                .where { $0.matches(search) }
                .where { if !search.showCompleted { !$0.isDone } }
                .join(List<Reminder>.Record.all) { $0.listID.eq($1.id) }
                .order { reminders, lists in
                    (lists.position, reminders.isDone, reminders.ordered(by: .dueDate, showCompleted: false))
                }
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
