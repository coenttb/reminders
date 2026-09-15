public import Foundation
public import Reminders
public import SQLiteData
public import Tagged

extension Lists.Home {
    /// Reads the home screen in one transaction, and again whenever a table it reads changes.
    public struct Request: FetchKeyRequest {
        /// The day the Today count is taken over.
        public var today: Range<Date>

        public init(today: Range<Date>) {
            self.today = today
        }

        public func fetch(_ db: Database) throws -> Lists.Home {
            let counts = try Reminder.Record.select {
                Counts.Columns(
                    all: $0.id.count(filter: !$0.isCompleted),
                    flagged: $0.id.count(filter: $0.flagged && !$0.isCompleted),
                    scheduled: $0.id.count(filter: $0.isScheduled),
                    today: $0.id.count(filter: $0.isDue(during: today))
                )
            }
            .fetchOne(db)
            return Lists.Home(
                lists: try Reminder.List.Record
                    .group(by: \.id)
                    .order(by: \.position)
                    .leftJoin(Reminder.Record.all) { $0.id.eq($1.listID) }
                    .select { Entry.Columns(list: $0, count: $1.id.count(filter: $1.status.eq(Reminder.Status.incomplete.rawValue))) }
                    .fetchAll(db)
                    .map { Lists.Home.Entry(list: $0.list.list, count: $0.count) },
                stats: Lists.Stats(all: counts?.all ?? 0, flagged: counts?.flagged ?? 0, scheduled: counts?.scheduled ?? 0, today: counts?.today ?? 0),
                usedTags: try Tag.Record
                    .where { $0.title.in(Reminder.Tagging.select { $0.tagID.text }) }
                    .order { $0.title.collate($localizedCaseInsensitive) }
                    .fetchAll(db)
                    .map(\.tag),
                rankedTags: try Tag.Record
                    .order { tag in
                        (
                            Reminder.Tagging.where { #sql("\($0.tagID) = \(tag.title)") }.count().desc(),
                            tag.title.collate($localizedCaseInsensitive)
                        )
                    }
                    .fetchAll(db)
                    .map(\.tag)
            )
        }

        @Selection
        fileprivate struct Counts {
            let all: Int
            let flagged: Int
            let scheduled: Int
            let today: Int
        }

        @Selection
        fileprivate struct Entry {
            let list: Reminder.List.Record
            let count: Int
        }
    }
}

extension Lists.Detail {
    /// Reads one detail in one transaction: its preference decides the query, so a change to
    /// the preference re-reads the rows along with it.
    public struct Request: FetchKeyRequest {
        public var detail: Lists.Detail?
        /// The day the Today detail shows.
        public var today: Range<Date>
        /// The row being edited sorts by this value until editing ends.
        public var place: Reminder?

        public init(detail: Lists.Detail?, today: Range<Date>, place: Reminder? = nil) {
            self.detail = detail
            self.today = today
            self.place = place
        }

        public func fetch(_ db: Database) throws -> Lists.Detail.Contents {
            guard let detail else { return Lists.Detail.Contents() }
            let preference = try Lists.Detail.Preference.Record.preference(for: detail).fetchOne(db)?.preference ?? detail.defaultPreference
            var list: Reminder.List?
            if case let .list(id) = detail {
                list = try Reminder.List.Record.find(id).fetchOne(db)?.list
            }
            let rows = try Reminder.Record
                .where { $0.belongs(to: detail, today: today) }
                .where { if !preference.showCompleted { !$0.isDone } }
                .order { $0.ordered(by: preference.ordering, showCompleted: preference.showCompleted, placing: place) }
                .rows()
                .fetchAll(db)
            return Lists.Detail.Contents(
                title: detail.title ?? list?.title ?? "",
                color: list?.color,
                preference: preference,
                rows: rows.map { Lists.Detail.Contents.Row(reminder: $0.value, color: $0.listColor) }
            )
        }
    }
}

extension Lists.Search {
    /// Reads the search in one transaction: the matches under their lists, how many of them are
    /// completed whether or not they are shown, and the tags completing a typed prefix.
    public struct Request: FetchKeyRequest {
        public var search: Lists.Search

        public init(search: Lists.Search) {
            self.search = search
        }

        public func fetch(_ db: Database) throws -> Lists.Search.Results {
            var results = Lists.Search.Results()
            // Nothing typed reads nothing: an idle search is not re-read on every write.
            guard search.matchesReminders || search.tagPrefix != nil else { return results }
            if let prefix = search.tagPrefix {
                let taken = search.tags.map(\.rawValue)
                results.suggestions = try Tag.Record
                    .where { $hasCaseInsensitivePrefix($0.title, prefix) && !$0.title.in(taken) }
                    .order { $0.title.collate($localizedCaseInsensitive) }
                    .fetchAll(db)
                    .map(\.tag)
            }
            results.completedCount = try Reminder.Record.where { $0.isDone && $0.matches(search) }.fetchCount(db)
            let rows = try Reminder.Record
                .where { $0.matches(search) }
                .where { if !search.showCompleted { !$0.isDone } }
                .join(Reminder.List.Record.all) { $0.listID.eq($1.id) }
                .order { reminders, lists in
                    (lists.position, reminders.isDone, reminders.ordered(by: .dueDate, showCompleted: false))
                }
                .select { Match.Columns(reminder: $0, tags: $0.tagList, list: $1) }
                .fetchAll(db)
            for row in rows {
                if results.sections.last?.list.id == row.list.id {
                    results.sections[results.sections.count - 1].reminders.append(row.value)
                } else {
                    results.sections.append(Lists.Search.Results.Section(list: row.list.list, reminders: [row.value]))
                }
            }
            return results
        }

        @Selection
        fileprivate struct Match {
            let reminder: Reminder.Record
            let tags: String?
            let list: Reminder.List.Record

            var value: Reminder { reminder.reminder(tags: Reminder.Record.tags(from: tags)) }
        }
    }
}

extension Reminder.Record {
    /// Reads which reminders are in their grace period, and again whenever that changes, so the
    /// grace timer follows the table however a reminder came to be completing.
    public struct Completing: FetchKeyRequest {
        public init() {}

        public func fetch(_ db: Database) throws -> Set<Reminder.ID> {
            Set(try Reminder.Record.where { $0.isCompleting }.select(\.id).fetchAll(db))
        }
    }
}
