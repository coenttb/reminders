import Clocks
import ComposableArchitecture2
import Dependencies
import DependenciesTestSupport
import Foundation
import Organizing
import Reminders
import Reminders_App
import Reminders_Interface
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
        store.send(.filterTapped(.today))
        #expect(store.filter == .today)
        try await store.state.$overview.load()
        #expect(store.overview.lists.map(\.list.title) == ["Personal", "Family", "Business"])
    }
}
