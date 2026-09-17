import Dependencies
import Foundation
public import Models
public import Reminder
public import Reminders
import Reminders_SQL
public import SQLiteData
import Tagged

// The read requests are the fetch keys: a feature observes a domain address and SQLite resolves it.
extension Reminders.Read.Today.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Summary {
        @Dependency(\.calendar) var calendar
        let today = calendar.day(containing: self.today)
        return Reminders.Summary(
            lists: try Models.List<Reminder>.Record
                .group(by: \.id)
                .order(by: \.position)
                .leftJoin(Reminder.Record.all) { $0.id.eq($1.listID) }
                .select { Models.List<Reminder>.Record.Entry.Columns(list: $0, count: $1.id.count(filter: $1.completed.eq(false))) }
                .fetchAll(db)
                .map(Models.List<Reminder>.Entry.init),
            counts: Reminders.Summary.Counts(
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

extension Reminders.Read.Preference.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Preference {
        try Reminders.Preference.Record.find(Reminders.Filter.Key(filter)).fetchOne(db).map(Reminders.Preference.init)
            ?? Reminders.Preference(ordering: .dueDate, showCompleted: filter == .completed)
    }
}

extension Reminders.Read.Page.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Page {
        @Dependency(\.calendar) var calendar
        let today = calendar.day(containing: self.today)
        let preference = try Reminders.Read.Preference.Request(for: filter).fetch(db)
        let matching = Reminder.Record.where { $0.belongs(to: filter, today: today) }
        let shown = matching.where { if !preference.showCompleted { !$0.isCompleted } }
        let total = try shown.fetchCount(db)
        return Reminders.Page(
            rows: try shown
                .order { $0.ordered(by: preference.ordering, showCompleted: preference.showCompleted, placing: including) }
                .limit(limit ?? total)
                .rows()
                .fetchAll(db)
                .map(Reminder.init),
            total: total,
            completed: try matching.where { $0.isCompleted }.fetchCount(db)
        )
    }
}

extension Reminders.Read.Search.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> Reminders.Page {
        let matching = Reminder.Record.where { $0.matches(query) }
        let shown = matching.where { if !query.showCompleted { !$0.isCompleted } }
        let total = try shown.fetchCount(db)
        return Reminders.Page(
            rows: try shown
                .join(Models.List<Reminder>.Record.all) { $0.listID.eq($1.id) }
                .order { reminders, lists in
                    (lists.position, reminders.isCompleted, reminders.ordered(by: .dueDate, showCompleted: false))
                }
                .limit(limit ?? total)
                .select { reminders, _ in Reminder.Record.Row.Columns(reminder: reminders, tags: reminders.tagTitles) }
                .fetchAll(db)
                .map(Reminder.init),
            total: total,
            completed: try matching.where { $0.isCompleted }.fetchCount(db)
        )
    }
}

extension Reminders.Tags.Suggest.Request: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> [Tag<Reminder>] {
        guard !prefix.isEmpty else { return [] }
        let taken = excluding.map(\.rawValue)
        return try Tag<Reminder>.Record
            .where { Reminders.Schema.$hasCaseInsensitivePrefix($0.title, prefix) && !$0.title.in(taken) }
            .order { $0.title.collate(Reminders.Schema.$localizedCaseInsensitive) }
            .fetchAll(db)
            .map(Tag<Reminder>.init)
    }
}
