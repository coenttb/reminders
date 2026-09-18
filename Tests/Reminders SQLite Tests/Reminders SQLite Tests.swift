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

    // The summary and a page are streams; the first element is the value now.
    func summary(_ reminders: Reminders) async throws -> Reminders.Summary? {
        try await reminders.read().first(where: { _ in true })
    }

    func page(_ reminders: Reminders, _ filter: Reminders.Read.Filter) async throws -> Reminders.Page? {
        try await reminders.read(page: filter).first(where: { _ in true })
    }

    @Test func `the summary counts the open reminders per list in order`() async throws {
        let (reminders, _) = try makeDatabase()
        #expect(try await summary(reminders)?.lists.map { "\($0.list.title) \($0.count)" } == ["Personal 1", "Family 1"])
    }

    @Test func `a reminder is created, read, updated, and deleted`() async throws {
        let (reminders, sample) = try makeDatabase()
        let personal = sample.lists[0].id
        var reminder = Reminder(id: Reminder.ID(UUID()), list: personal, title: "Water plants", created: now)
        try await reminders.create(reminder)
        #expect(try await page(reminders, .list(personal))?.rows.map(\.title) == ["Groceries", "Haircut", "Water plants"])
        reminder.completed = true
        try await reminders.update(reminder)
        #expect(try reminders.read(reminder.id).completed)
        #expect(try await summary(reminders)?.lists.map(\.count) == [1, 1])
        try await reminders.delete(reminder.id)
        #expect(throws: Reminders.Read.Error.notFound) { try reminders.read(reminder.id) }
        await #expect(throws: Reminders.Update.Error.notFound) { try await reminders.update(reminder) }
    }

    @Test func `completion is its own write`() async throws {
        let (reminders, sample) = try makeDatabase()
        let groceries = sample.reminders[0].id
        try await reminders.update.complete(groceries, true)
        #expect(try reminders.read(groceries).completed)
        try await reminders.update.complete(groceries, false)
        #expect(try !reminders.read(groceries).completed)
        await #expect(throws: Reminders.Update.Error.notFound) { try await reminders.update.complete(Reminder.ID(UUID()), true) }
    }

    @Test func `deleting the last list installs the default one`() async throws {
        let (reminders, sample) = try makeDatabase()
        let replacement = Models.List<Reminder>.ID(UUID())
        for list in sample.lists { try await reminders.lists.delete(list.id, replacement: replacement) }
        #expect(try await summary(reminders)?.lists.map(\.list) == [.default(id: replacement)])
        #expect(try await page(reminders, .all)?.rows.isEmpty == true)
    }

    // A page stream yields the value now and again after every write it depends on.
    @Test func `a page stream follows the writes`() async throws {
        let (reminders, sample) = try makeDatabase()
        let personal = sample.lists[0].id
        var pages = reminders.read(page: .list(personal)).makeAsyncIterator()
        #expect(try await pages.next()?.rows.map(\.title) == ["Groceries", "Haircut"])
        try await reminders.create(Reminder(id: Reminder.ID(UUID()), list: personal, title: "Water plants", created: now))
        #expect(try await pages.next()?.rows.map(\.title) == ["Groceries", "Haircut", "Water plants"])
    }
}
