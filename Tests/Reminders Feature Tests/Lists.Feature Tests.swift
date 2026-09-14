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
            let groceries = await store.state.lists.reminders[0].id
            await store.send(.reminderCompleteButtonTapped(groceries))?.value
            await store.expect { _ in }?.value
            #expect(await store.state.lists.reminder(groceries)?.status == .completed)
            let personal = await store.state.lists.orderedLists[0].id
            await store.send(.listTapped(personal))?.value
            await store.send(.orderingSelected(.title))?.value
            await store.send(.showCompletedButtonTapped)?.value
            #expect(await store.state.lists.preference(for: .list(personal)).showCompleted)
            await store.send(.newReminderButtonTapped)?.value
            await store.modify {
                if case var .reminder(form) = $0.destination {
                    form.reminder.title = "Water plants"
                    $0.destination = .reminder(form)
                }
            }?.value
            await store.send(.destination(.reminder(.tagAdded("garden"))))?.value
            await store.send(.destination(.reminder(.tagAdded("ADULTING"))))?.value
            await store.send(.destination(.reminder(.saveButtonTapped)))?.value
            #expect(await store.state.destination == nil)
            #expect(await store.state.lists.reminders.count == 12)
            #expect(await store.state.lists.reminders.last?.tags == ["garden", "adulting"])
            #expect(await store.state.lists.tags.filter { $0.title.lowercased() == "adulting" }.count == 1)
            await store.dismount()
            @Dependency(\.defaultDatabase) var database
            let stored = try await database.read { db in try Lists.load(db) }
            #expect(stored?.reminder(groceries)?.status == .completed)
            #expect(stored?.detail == .list(personal))
            #expect(stored?.preference(for: .list(personal)).ordering == .title)
            #expect(stored?.preference(for: .list(personal)).showCompleted == true)
            #expect(stored?.reminders.last?.title == "Water plants")
        }
    }
}
