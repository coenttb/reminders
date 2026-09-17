import Clocks
import ComposableArchitecture2
import Dependencies
import DependenciesTestSupport
import Foundation
import Models
import Reminder
import Reminders
import Reminders_App
import Reminders_Feature
import Reminders_Sample
import Reminders_SQL
import Reminders_SQLite
import SQLiteData
import SwiftUI
import Testing

@Suite(.dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)))
    $0.calendar = Calendar(identifier: .gregorian)
    $0.continuousClock = ImmediateClock()
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
})
struct `Reminder root` {
    @Test func `constructs from a store and reads the database through it`() async throws {
        let store = Store(initialState: Reminders.Feature.State()) { Reminders.Feature() }
        _ = Reminders.Screen(store: store)
        store.send(.overview(.filterTapped(.today)))
        #expect(store.listing?.filter == .today)
        try await store.state.overview.$summary.load()
        #expect(store.overview.summary.lists.map(\.list.title) == ["Personal", "Family", "Business"])
    }

    #if DEBUG
    @Test func `the sample menu replaces the database and tells the screen`() async throws {
        @Dependency(\.defaultDatabase) var database
        let store = Store(initialState: Reminders.Feature.State()) { Reminders.Feature() }
        let sample = Store(initialState: Reminders.Sample.Feature.State()) { Reminders.Sample.Feature(replaced: { store.send(.databaseReplaced) }) }
        store.send(.overview(.filterTapped(.today)))
        try await database.write { db in try Reminder.Record.delete().execute(db) }
        await sample.send(.seedButtonTapped)?.value
        #expect(store.listing?.filter == nil)
        #expect(try await database.read { db in try Reminder.Record.all.fetchCount(db) } == 11)
    }
    #endif
}
