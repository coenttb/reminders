import ComposableArchitecture2
import ComposableArchitectureTestSupport
import Dependencies
import DependenciesTestSupport
import Foundation
import Interface_ComposableArchitecture
import List
import Operation
import Reminder
import Reminders
import Reminders_Dependency
import Reminders_Feature
import Reminders_Sample
import Reminders_SQL
import Reminders_SQLite
import Tagged
import Testing

@Suite(.dependencies {
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)))
})
@MainActor
struct `Reminders feature` {
    @Dependency(\.reminders) var reminders

    let sample = Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890))
    var personal: List<Reminder>.ID { sample.lists[0].id }

    // Opening a page starts its observation, which never ends; a test awaits the page's writes, not the action.
    func page(_ store: TestStore<Reminders.Feature>) throws -> Reminders.Read.Page.Feature.State {
        try #require(store.page)
    }

    @Test func `a new row is drafted, edited in place, and created when the editor leaves`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.modify { $0.page = .init(.list(personal)) }
            #expect(store.page?.contents.request.filter == .list(personal))
            store.modify { $0.page?.editing = .init(Reminder.Draft(list: personal)) }
            store.modify { $0.page?.editing?.title = "Water plants" }
            // Dismissing the editor creates the row.
            await store.modify { $0.page?.editing = nil }?.value
            var pages = reminders.read.page(filter: .list(personal)).makeAsyncIterator()
            let page = try await pages.next()
            #expect(page?.rows.map(\.title) == ["Groceries", "Haircut", "Water plants"])
            while store.page?.contents.rows?.count != 3 { await Task.yield() }
            await store.dismount()
        }
    }

    @Test func `a blank draft is dropped when the editor leaves`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.modify { $0.page = .init(.list(personal)) }
            store.modify { $0.page?.editing = .init(Reminder.Draft(list: personal)) }
            await store.modify { $0.page?.editing = nil }?.value
            var pages = reminders.read.page(filter: .list(personal)).makeAsyncIterator()
            let page = try await pages.next()
            #expect(page?.rows.count == 2)
            await store.dismount()
        }
    }

    // A failed call is recorded on the task id it rode, where the view reads it.
    @Test func `a failed call is recorded on the page's writes`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.modify { $0.page = .init(.list(personal)) }
            store.send(.page(.update.complete(Reminder.ID(UUID()), true)))
            await #expect(throws: Reminders.Update.Error.notFound) { try await page(store).writes() }
            #expect(store.page?.writes.taskError is Reminders.Update.Error)
            await store.dismount()
        }
    }

    // A delete is a call; the observed page follows.
    @Test func `a delete call removes the row from the observed page`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.modify { $0.page = .init(.list(personal)) }
            while store.page?.contents.rows == nil { await Task.yield() }
            let groceries = try #require(store.page?.contents.rows?.first(where: { $0.title == "Groceries" }))
            store.send(.page(.delete(groceries.id)))
            try await page(store).writes()
            while store.page?.contents.rows?.contains(where: { $0.id == groceries.id }) == true { await Task.yield() }
            #expect(store.page?.contents.rows?.map(\.title) == ["Haircut"])
            await store.dismount()
        }
    }

    // Deleting a list is a call; the page showing that list is gone.
    @Test func `a list delete closes its page`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.modify { $0.page = .init(.list(personal)) }
            store.send(.call(.lists.delete(personal)))
            #expect(store.page == nil)
            try await store.writes()
            while store.summary.lists?.map(\.list.title) != ["Family"] { await Task.yield() }
            await store.dismount()
        }
    }
}
