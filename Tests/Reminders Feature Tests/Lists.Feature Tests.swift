import ComposableArchitecture2
import ComposableArchitectureTestSupport
import Dependencies
import DependenciesTestSupport
import Foundation
import Reminders
import Reminders_Feature
import Reminders_SQLiteData
import SQLiteData
import Testing
import Tagged

@Suite(.dependencies {
    try $0.bootstrapDatabase()
    $0.continuousClock = ImmediateClock()
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    $0.uuid = .incrementing
})
struct `Lists feature` {
    @Test func `completing a reminder finishes after the grace period and everything persists`() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let store = await TestStoreActor(initialState: Lists.Feature.State()) { Lists.Feature() }
            await store.expect { _ in }?.value
            let groceries = await store.state.lists.reminders[0].id
            await store.send(.reminderCompleteButtonTapped(groceries))?.value
            #expect(await store.state.lists.reminder(groceries)?.status == .completed)
            let personal = await store.state.lists.orderedLists[0].id
            await store.send(.listTapped(personal))?.value
            await store.send(.orderingSelected(.title))?.value
            await store.send(.newReminderButtonTapped)?.value
            await store.modify { $0.reminder?.title = "Water plants" }?.value
            await store.send(.reminderFormSaved)?.value
            #expect(await store.state.lists.reminders.count == 12)
            await store.dismount()
            @Dependency(\.defaultDatabase) var database
            let stored = try await database.read { db in try Lists.load(db) }
            #expect(stored?.reminder(groceries)?.status == .completed)
            #expect(stored?.detail == .list(personal))
            #expect(stored?.preference(for: .list(personal)).ordering == .title)
            #expect(stored?.reminders.last?.title == "Water plants")
        }
    }
}
