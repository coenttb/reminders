import ComposableArchitecture2
import ComposableArchitectureTestSupport
import Dependencies
import DependenciesTestSupport
import Foundation
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
struct `Reminders feature` {
    @Dependency(\.reminders) var reminders

    let sample = Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890))
    var personal: Models.List<Reminder>.ID { sample.lists[0].id }

    @Test func `a new row is inserted, edited in place, and written when the session ends`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = await TestStoreActor(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            await store.send(.overview(.listTapped(personal)))?.value
            #expect(await store.state.listing?.filter == .list(personal))
            await store.send(.listing(.newReminderButtonTapped))?.value
            let editing = try #require(await store.state.listing?.editing)
            #expect(try reminders.read(editing.id).isBlank)
            await store.modify { $0.listing?.editing?.draft.title = "Water plants" }?.value
            await store.send(.listing(.doneButtonTapped))?.value
            #expect(await store.state.listing?.editing == nil)
            #expect(try reminders.read(editing.id).title == "Water plants")
            #expect(try reminders.read(page: .list(personal)).rows.map(\.title) == ["Groceries", "Haircut", "Water plants"])
            await store.dismount()
        }
    }

    @Test func `a blank row is dropped when the session ends`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = await TestStoreActor(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            await store.send(.overview(.listTapped(personal)))?.value
            await store.send(.listing(.newReminderButtonTapped))?.value
            let editing = try #require(await store.state.listing?.editing)
            await store.send(.listing(.backgroundTapped))?.value
            #expect(throws: Reminders.Read.Error.notFound) { try reminders.read(editing.id) }
            await store.dismount()
        }
    }

    @Test func `a failure travels up to the root`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = await TestStoreActor(initialState: Reminders.Feature.State()) { Reminders.Feature() }
            await store.send(.overview(.listTapped(personal)))?.value
            await store.send(.listing(.reminderCompleteButtonTapped(Reminder.ID(UUID()))))?.value
            #expect(await store.state.failure != nil)
            await store.dismount()
        }
    }
}
