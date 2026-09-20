import ComposableArchitecture2
import ComposableArchitectureTestSupport
import Dependencies
import DependenciesTestSupport
import Foundation
import Interface_ComposableArchitecture
import List
import Reminder
import Reminders
import Reminders_Dependency
import Reminders_Feature
import Reminders_Sample
import Reminders_SQLite
import Testing

@Suite(.dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Date(timeIntervalSince1970: 123)))
})
@MainActor
struct DeletionLifecycle {
    @Dependency(\.reminders) var reminders

    @Test func deletingAListDiscardsItsUnsavedReminder() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let sample = Reminders.sample(at: Date(timeIntervalSince1970: 123))
            let list = sample.lists[0].id
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(list)) }
            store.modify { $0.read.page?.editing = .init(Reminder.Draft(list: list, title: "Must not be created")) }
            store.send(.call(.lists.delete(list)))
            #expect(store.read.page == nil)
            try await store.writes()
            var values = reminders.read.page(filter: .all).makeAsyncIterator()
            let value = try await values.next()
            #expect(value?.rows.contains(where: { $0.title == "Must not be created" }) == false)
            await store.dismount()
        }
    }

    @Test func missingUpdateIsRetainedOnTheOwningTask() async throws {
        try await TestExhaustivity.$current.withValue(.off) {
            let original = Reminders.sample(at: Date(timeIntervalSince1970: 123)).reminders[0]
            let store = TestStore(initialState: Reminders.State()) { reminders }
            store.modify { $0.read.page = .init(.list(original.list)) }
            store.modify { $0.read.page?.editing = .init(original) }
            store.modify { $0.read.page?.editing?.title = "Changed" }
            try await reminders.delete(original.id)
            await store.modify { $0.read.page?.editing = nil }?.value
            let page = try #require(store.read.page)
            #expect(page.writes.taskError as? Reminders.Update.Error == .notFound)
            await store.dismount()
        }
    }
}
