import Optic
import ComposableArchitecture2
import CustomDump
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
    func page(_ store: TestStore<Reminders>) throws -> Reminders.Read.Page.State {
        try #require(store.read.page)
    }

    @Test func `a new row is drafted, edited in place, and created when the editor leaves`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(personal)) }
            #expect(store.read.page?.contents.request.filter == .list(personal))
            store.modify { $0.read.page?.editing = .init(Reminder.Draft(list: personal)) }
            store.modify { $0.read.page?.editing?.title = "Water plants" }
            // Dismissing the editor creates the row.
            await store.modify { $0.read.page?.editing = nil }?.value
            var pages = reminders.read.page(filter: .list(personal)).makeAsyncIterator()
            let page = try await pages.next()
            #expect(page?.rows.map(\.title) == ["Groceries", "Haircut", "Water plants"])
            while store.read.page?.contents.rows?.count != 3 { await Task.yield() }
            await store.dismount()
        }
    }

    @Test func `a blank draft is dropped when the editor leaves`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(personal)) }
            store.modify { $0.read.page?.editing = .init(Reminder.Draft(list: personal)) }
            await store.modify { $0.read.page?.editing = nil }?.value
            var pages = reminders.read.page(filter: .list(personal)).makeAsyncIterator()
            let page = try await pages.next()
            #expect(page?.rows.count == 2)
            await store.dismount()
        }
    }

    // A failed call is recorded on the task id it rode, where the view reads it.
    @Test func `a failed call is recorded on the page's writes`() async throws {
        await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(personal)) }
            store.send(.read(.page(.update.complete(Reminder.ID(UUID()), true))))
            await #expect(throws: Reminders.Update.Error.notFound) { try await page(store).writes() }
            #expect(store.read.page?.writes.taskError is Reminders.Update.Error)
            await store.dismount()
        }
    }

    // A delete is a call; the observed page follows.
    @Test func `a delete call closes its editor and removes the row from the observed page`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(personal)) }
            while store.read.page?.contents.rows == nil { await Task.yield() }
            let groceries = try #require(store.read.page?.contents.rows?.first(where: { $0.title == "Groceries" }))
            store.modify { $0.read.page?.editing = .init(groceries) }
            store.send(.read(.page(.delete(groceries.id))))
            #expect(store.read.page?.editing == nil)
            try await page(store).writes()
            while store.read.page?.contents.rows?.contains(where: { $0.id == groceries.id }) == true { await Task.yield() }
            #expect(store.read.page?.contents.rows?.map(\.title) == ["Haircut"])
            await store.dismount()
        }
    }

    @Test func `list deletion projection excludes other action branches`() {
        let deleting: (Reminders.Action) -> List<Reminder>.ID? = \.call?.lists?.delete?.id
        expectNoDifference(deleting(.call(.lists.delete(personal))), personal)
        #expect(deleting(.call(.delete(sample.reminders[0].id))) == nil)
        #expect(deleting(.read(.page(.lists.delete(personal)))) == nil)
    }

    // Deleting a list is a call; the page showing that list is gone.
    @Test func `a list delete closes its page`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(personal)) }
            store.send(.call(.lists.delete(personal)))
            #expect(store.read.page == nil)
            try await store.writes()
            while store.read.lists?.map(\.list.title) != ["Family"] { await Task.yield() }
            await store.dismount()
        }
    }

    @Test func `editing overlays the observed record then saves its final draft`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(personal)) }
            while store.read.page?.contents.rows == nil { await Task.yield() }
            let original = try #require(store.read.page?.rows.first)
            store.modify { $0.read.page?.editing = .init(original) }
            store.modify { $0.read.page?.editing?.title = "Edited title" }
            let overlay = try #require(store.read.page?.rows.first(where: { $0.id == original.id }))
            expectNoDifference(overlay.title, "Edited title")
            expectNoDifference(overlay.created, original.created)
            expectNoDifference(try reminders.read(original.id), original)
            await store.modify { $0.read.page?.editing = nil }?.value
            let saved = try reminders.read(original.id)
            expectNoDifference(saved.title, "Edited title")
            expectNoDifference(saved.id, original.id)
            expectNoDifference(saved.created, original.created)
            await store.dismount()
        }
    }

}

private enum DeletionFailure: Error, Equatable { case refused }

extension `Reminders feature` {
    @Test(arguments: [false, true])
    func `failed list deletion closes only its matching page and keeps route ownership`(scoped: Bool) async throws {
        await TestExhaustivity.$current.withValue(.off) {
            let domain = Reminders(
                create: reminders.create, read: reminders.read, update: reminders.update, delete: reminders.delete,
                lists: .init(create: reminders.lists.create, delete: .init { _ in throw DeletionFailure.refused })
            )
            let store = TestStore(initialState: Reminders.State()) { domain }
            store.modify { $0.read.page = .init(.list(personal)) }
            if scoped { store.send(.lists(.call(.delete(personal)))) }
            else { store.send(.call(.lists.delete(personal))) }
            #expect(store.read.page == nil)
            let task = scoped ? store.lists.writes : store.writes
            await #expect(throws: DeletionFailure.refused) { try await task() }
            #expect(store.read.page == nil)
            if scoped { #expect(store.writes.taskError == nil) }
            else { #expect(store.lists.writes.taskError == nil) }
            await store.dismount()
        }
    }

    @Test func `deleting a different list preserves the open page`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(personal)) }
            let other = sample.lists[1].id
            store.send(.lists(.call(.delete(other))))
            #expect(store.read.page?.filter.list == personal)
            try await store.lists.writes()
            #expect(store.read.page?.filter.list == personal)
            await store.dismount()
        }
    }
}
