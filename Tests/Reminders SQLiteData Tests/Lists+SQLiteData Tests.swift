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
        let new = Reminder.ID(UUID())
        lists.upsert(Reminder(id: new, list: lists.orderedLists[0].id, title: "New", due: now, hasTime: true, tags: ["fresh"], location: .gettingInCar, repeats: .weekly))
        lists.editing = new
        try database.write { db in try Lists.persist(lists, in: db) }
        let stored = try database.read { db in try Lists.load(db) }
        #expect(stored == lists)
        #expect(stored?.reminders.contains { $0.title == "New" && $0.hasTime && $0.location == .gettingInCar && $0.repeats == .weekly } == true)
        #expect(stored?.editing == new)
        #expect(try database.read { db in try Reminder.Tagging.all.fetchCount(db) } == lists.reminders.reduce(0) { $0 + $1.tags.count })
    }

    @Test func `a tag renamed only in case survives a round trip`() throws {
        let database = try DatabaseQueue()
        try Lists.migrate(database)
        var lists = Lists.sample(at: now)
        try database.write { db in try Lists.seed(lists, in: db) }
        lists.rename(tag: "social", to: "Social")
        try database.write { db in try Lists.persist(lists, in: db) }
        let stored = try database.read { db in try Lists.load(db) }
        #expect(stored == lists)
        #expect(stored?.tags.contains(Tag(title: "Social")) == true)
        #expect(stored?.reminders.filter { $0.tags.contains("Social") }.count == 3)
    }
}
