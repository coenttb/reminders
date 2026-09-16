import Foundation
import Organizing
public import Reminders
public import Reminders_Interface
public import SQLiteData
import Tagged

extension Reminders.Overview.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Overview {
        let counts = try Reminder.Record.select {
            Counts.Columns(
                all: $0.id.count(filter: !$0.isCompleted),
                flagged: $0.id.count(filter: $0.flagged && !$0.isCompleted),
                scheduled: $0.id.count(filter: $0.isScheduled),
                today: $0.id.count(filter: $0.isDue(during: today))
            )
        }
        .fetchOne(db)
        return Reminders.Overview(
            lists: try List<Reminder>.Record
                .group(by: \.id)
                .order(by: \.position)
                .leftJoin(Reminder.Record.all) { $0.id.eq($1.listID) }
                .select { Entry.Columns(list: $0, count: $1.id.count(filter: $1.status.eq(Reminder.Record.incomplete))) }
                .fetchAll(db)
                .map { List<Reminder>.Entry(list: List($0.list), count: $0.count) },
            counts: Reminders.Filter.Counts(all: counts?.all ?? 0, flagged: counts?.flagged ?? 0, scheduled: counts?.scheduled ?? 0, today: counts?.today ?? 0),
            usedTags: try Tag<Reminder>.Record
                .where { $0.title.in(Reminder.Tagging.select { $0.tagID.text }) }
                .order { $0.title.collate($localizedCaseInsensitive) }
                .fetchAll(db)
                .map(Tag<Reminder>.init),
            rankedTags: try Tag<Reminder>.Record
                .order { tag in
                    (
                        Reminder.Tagging.where { $0.tagID.text.eq(tag.title) }.count().desc(),
                        tag.title.collate($localizedCaseInsensitive)
                    )
                }
                .fetchAll(db)
                .map(Tag<Reminder>.init)
        )
    }
}
