import Foundation
import Reminders
import Reminders_SQLiteData
import SQLiteData
import Testing
import Tagged

@Suite struct `Lists SQLite storage` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)

    @Test func `migrates, seeds once, and round-trips the graph, preferences, and open detail`() throws {
        let database = try DatabaseQueue()
        try Lists.migrate(database)
        #expect(try database.read { db in try Lists.load(db) } == nil)
        let sample = Lists.sample(at: now)
        try database.write { db in
            try Lists.seed(sample, in: db)
            try Lists.seed(sample, in: db)
        }
        #expect(try database.read { db in try Lists.load(db) } == sample)
        var lists = sample
        let personal = Lists.Detail.list(lists.orderedLists[0].id)
        lists.set(ordering: .title, for: personal)
        lists.toggleShowCompleted(for: personal)
        lists.detail = personal
        lists.rename(tag: "social", to: "friends")
        lists.delete(list: lists.orderedLists[2].id)
        lists.upsert(Reminder(id: Reminder.ID(UUID()), list: lists.orderedLists[0].id, title: "New", tags: ["fresh"]))
        try database.write { db in try Lists.persist(lists, in: db) }
        let stored = try database.read { db in try Lists.load(db) }
        #expect(stored == lists)
        #expect(try database.read { db in try Reminder.Tagging.all.fetchCount(db) } == lists.reminders.reduce(0) { $0 + $1.tags.count })
    }
}
