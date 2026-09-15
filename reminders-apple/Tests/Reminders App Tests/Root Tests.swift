import ComposableArchitecture2
import Dependencies
import DependenciesTestSupport
import Foundation
import Reminders
import Reminders_App
import Reminders_Feature
import SQLiteData
import SwiftUI
import Testing

@Suite(.dependencies {
    try $0.bootstrapDatabase()
    $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
})
struct `Lists root` {
    @Test func `constructs from a store and reads the database through it`() async throws {
        let store = Store(initialState: Lists.Feature.State()) { Lists.Feature() }
        _ = Root(store: store)
        store.send(.statTapped(.today))
        #expect(store.detail == .today)
        // The first run seeded the sample, which the home reads back.
        try await store.state.$home.load()
        #expect(store.home.lists.map(\.list.title) == ["Personal", "Family", "Business"])
    }
}
