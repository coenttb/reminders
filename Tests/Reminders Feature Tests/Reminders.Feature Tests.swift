import ComposableArchitecture2
import ComposableArchitectureTestSupport
import Dependencies
import DependenciesTestSupport
import Foundation
import Interface_ComposableArchitecture
import Models
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
    var personal: Models.List<Reminder>.ID { sample.lists[0].id }

    // Opening a page starts its observation, which never ends; a test awaits the page's writes, not the action.
    func page(_ store: TestStore<Reminders.Feature>) throws -> Reminders.Read.Page.Feature.State {
        try #require(store.listing)
    }

    @Test func `a new row is inserted, edited in place, and written when the session ends`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.send(.listTapped(personal))
            #expect(store.listing?.observing.request.filter == .list(personal))
            store.send(.listing(.newReminderButtonTapped))
            try await page(store).writes()
            let editing = try #require(store.listing?.editing)
            #expect(try reminders.read(editing.id).isBlank)
            store.modify { $0.listing?.editing?.request.reminder.title = "Water plants" }
            store.send(.listing(.doneButtonTapped))
            try await page(store).writes()
            #expect(store.listing?.editing == nil)
            #expect(try reminders.read(editing.id).title == "Water plants")
            while store.listing?.observing.value?.rows.count != 3 { await Task.yield() }
            #expect(store.listing?.observing.value?.rows.map(\.title) == ["Groceries", "Haircut", "Water plants"])
            await store.dismount()
        }
    }

    @Test func `a blank row is dropped when the session ends`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.send(.listTapped(personal))
            store.send(.listing(.newReminderButtonTapped))
            try await page(store).writes()
            let editing = try #require(store.listing?.editing)
            store.send(.listing(.backgroundTapped))
            try await page(store).writes()
            #expect(throws: Reminders.Read.Error.notFound) { try reminders.read(editing.id) }
            await store.dismount()
        }
    }

    // A failed write is recorded on the page's task id, where the view reads it.
    @Test func `a failed write is recorded on the page's writes`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.send(.listTapped(personal))
            store.send(.listing(.call(.update(.complete(Reminder.ID(UUID()), true)))))
            await #expect(throws: Reminders.Update.Error.notFound) { try await page(store).writes() }
            #expect(store.listing?.writes.taskError is Reminders.Update.Error)
            await store.dismount()
        }
    }

    // A delete is a call carried by an action; the observed page follows.
    @Test func `a delete call removes the row from the observed page`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.send(.listTapped(personal))
            while store.listing?.observing.value == nil { await Task.yield() }
            let groceries = try #require(store.listing?.observing.value?.rows.first(where: { $0.title == "Groceries" }))
            store.send(.listing(.call(.delete(.call(groceries.id)))))
            try await page(store).writes()
            while store.listing?.observing.value?.rows.contains(where: { $0.id == groceries.id }) == true { await Task.yield() }
            #expect(store.listing?.observing.value?.rows.map(\.title) == ["Haircut"])
            await store.dismount()
        }
    }

    // Deleting a list is a call minted at the root; the page showing that list is gone.
    @Test func `a list delete closes its page`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = TestStore(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            store.send(.listTapped(personal))
            store.send(.listDeleted(personal))
            #expect(store.listing == nil)
            try await store.writes()
            while store.overview.value?.lists.map(\.list.title) != ["Family"] { await Task.yield() }
            await store.dismount()
        }
    }
}
