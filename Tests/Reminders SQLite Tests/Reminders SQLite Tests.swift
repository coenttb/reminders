import Dependencies
import DependenciesTestSupport
import Foundation
import Models
import Reminder
import Reminders
import Reminders_Sample
import Reminders_SQL
import Reminders_SQLite
import SQLiteData
import Tagged
import Testing

@Suite(.dependencies { $0.date.now = Date(timeIntervalSince1970: 1_234_567_890) })
struct `Reminders SQLite storage` {
    @Dependency(\.date.now) var now

    func makeDatabase() throws -> (reminders: Reminders, sample: Reminders.Sample) {
        let database = try Reminders.Schema.database()
        let sample = Reminders.sample(at: now)
        try database.write { db in try sample.initialize(in: db) }
        return (.sqlite(database), sample)
    }

    @Test func `the summary counts the open reminders per list in order`() throws {
        let (reminders, _) = try makeDatabase()
        #expect(try reminders.read().lists.map { "\($0.list.title) \($0.count)" } == ["Personal 1", "Family 1"])
    }

    @Test func `a reminder is created, read, updated, and deleted`() async throws {
        let (reminders, sample) = try makeDatabase()
        let personal = sample.lists[0].id
        var reminder = Reminder(id: Reminder.ID(UUID()), list: personal, title: "Water plants", created: now)
        try await reminders.create(reminder)
        #expect(try reminders.read(page: .list(personal)).rows.map(\.title) == ["Groceries", "Haircut", "Water plants"])
        reminder.completed = true
        try await reminders.update(reminder)
        #expect(try reminders.read(reminder.id).completed)
        #expect(try reminders.read().lists.map(\.count) == [1, 1])
        try await reminders.delete(reminder.id)
        #expect(throws: Reminders.Read.Error.notFound) { try reminders.read(reminder.id) }
        await #expect(throws: Reminders.Update.Error.notFound) { try await reminders.update(reminder) }
    }

    @Test func `deleting the last list installs the default one`() async throws {
        let (reminders, sample) = try makeDatabase()
        let replacement = Models.List<Reminder>.ID(UUID())
        for list in sample.lists { try await reminders.lists.delete(list.id, replacement: replacement) }
        #expect(try reminders.read().lists.map(\.list) == [.default(id: replacement)])
        #expect(try reminders.read(page: .all).rows.isEmpty)
    }

    // Observing a request yields the value now and again after every write it depends on.
    @Test func `an observed page follows the writes`() async throws {
        let (reminders, sample) = try makeDatabase()
        let personal = sample.lists[0].id
        var pages = reminders.observe(Reminders.Read.Page.Request(page: .list(personal))).makeAsyncIterator()
        #expect(try await pages.next()?.rows.map(\.title) == ["Groceries", "Haircut"])
        try await reminders.create(Reminder(id: Reminder.ID(UUID()), list: personal, title: "Water plants", created: now))
        #expect(try await pages.next()?.rows.map(\.title) == ["Groceries", "Haircut", "Water plants"])
    }
}
