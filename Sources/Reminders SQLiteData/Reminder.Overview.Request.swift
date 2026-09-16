public import Foundation
public import Organizing
public import Reminders
public import Reminders_Application
public import SQLiteData
import Tagged

extension Reminder.Overview {
    public struct Request: FetchKeyRequest {
        public var today: Range<Date>

        public init(today: Range<Date>) {
            self.today = today
        }

        public func fetch(_ db: Database) throws -> Reminder.Overview {
            let counts = try Reminder.Record.select {
                Counts.Columns(
                    all: $0.id.count(filter: !$0.isCompleted),
                    flagged: $0.id.count(filter: $0.flagged && !$0.isCompleted),
                    scheduled: $0.id.count(filter: $0.isScheduled),
                    today: $0.id.count(filter: $0.isDue(during: today))
                )
            }
            .fetchOne(db)
            return Reminder.Overview(
                lists: try List<Reminder>.Record
                    .group(by: \.id)
                    .order(by: \.position)
                    .leftJoin(Reminder.Record.all) { $0.id.eq($1.listID) }
                    .select { Entry.Columns(list: $0, count: $1.id.count(filter: $1.status.eq(Reminder.Record.incomplete))) }
                    .fetchAll(db)
                    .map { List<Reminder>.Entry(list: $0.list.list, count: $0.count) },
                counts: Reminder.Filter.Counts(all: counts?.all ?? 0, flagged: counts?.flagged ?? 0, scheduled: counts?.scheduled ?? 0, today: counts?.today ?? 0),
                usedTags: try Tag<Reminder>.Record
                    .where { $0.title.in(Reminder.Tagging.select { $0.tagID.text }) }
                    .order { $0.title.collate($localizedCaseInsensitive) }
                    .fetchAll(db)
                    .map(\.tag),
                rankedTags: try Tag<Reminder>.Record
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
            let list: List<Reminder>.Record
            let count: Int
        }
    }
}
