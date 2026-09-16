import Foundation
import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminders.Overview.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Overview {
        let counts = try Reminder.Record.select {
            Reminder.Record.Counts.Columns(
                all: $0.id.count(filter: !$0.isCompleted),
                flagged: $0.id.count(filter: $0.flagged && !$0.isCompleted),
                scheduled: $0.id.count(filter: $0.isScheduled),
                today: $0.id.count(filter: $0.isDue(during: today))
            )
        }
        .fetchOne(db) ?? Reminder.Record.Counts()
        let tags = try Tag<Reminder>.Record
            .group(by: \.title)
            .leftJoin(Reminders.Tagging.all) { $0.title.eq($1.tagID.text) }
            .order { ($1.reminderID.count().desc(), $0.title.collate($localizedCaseInsensitive)) }
            .select { Tag<Reminder>.Record.Entry.Columns(tag: $0, count: $1.reminderID.count()) }
            .fetchAll(db)
        return Reminders.Overview(
            lists: try List<Reminder>.Record
                .group(by: \.id)
                .order(by: \.position)
                .leftJoin(Reminder.Record.all) { $0.id.eq($1.listID) }
                .select { List<Reminder>.Record.Entry.Columns(list: $0, count: $1.id.count(filter: $1.status.eq(.incomplete))) }
                .fetchAll(db)
                .map { List<Reminder>.Entry(list: List($0.list), count: $0.count) },
            counts: Reminders.Filter.Counts(all: counts.all, flagged: counts.flagged, scheduled: counts.scheduled, today: counts.today),
            usedTags: tags.filter { $0.count > 0 }.map { Tag($0.tag) }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending },
            rankedTags: tags.map { Tag($0.tag) }
        )
    }
}
