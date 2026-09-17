import Models
import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData
import Tagged

extension Reminders.Overview.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Overview.Result {
        Reminders.Overview.Result(
            lists: try Models.List<Reminder>.Record
                .group(by: \.id)
                .order(by: \.position)
                .leftJoin(Reminder.Record.all) { $0.id.eq($1.listID) }
                .select { Models.List<Reminder>.Record.Entry.Columns(list: $0, count: $1.id.count(filter: $1.completed.eq(false))) }
                .fetchAll(db)
                .map(Models.List<Reminder>.Entry.init),
            counts: Reminders.Overview.Counts(
                try Reminder.Record.select {
                    Reminder.Record.Counts.Columns(
                        all: $0.id.count(filter: !$0.isCompleted),
                        flagged: $0.id.count(filter: $0.flagged && !$0.isCompleted),
                        scheduled: $0.id.count(filter: $0.isScheduled),
                        today: $0.id.count(filter: $0.isDue(during: today))
                    )
                }
                .fetchOne(db) ?? Reminder.Record.Counts()
            ),
            tags: try Tag<Reminder>.Record
                .group(by: \.title)
                .leftJoin(Reminders.Tagging.all) { $0.title.eq($1.tagID.text) }
                .order { ($1.reminderID.count().desc(), $0.title.collate(Reminders.Schema.$localizedCaseInsensitive)) }
                .select { Tag<Reminder>.Record.Entry.Columns(tag: $0, count: $1.reminderID.count()) }
                .fetchAll(db)
                .map(Tag<Reminder>.Entry.init)
        )
    }
}
