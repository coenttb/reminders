import ComposableArchitecture2
import Dependencies
import DependenciesTestSupport
import Foundation
import Interface_ComposableArchitecture
import Models
import Reminder
import Reminders
import Reminders_SwiftUI
import Reminders_Feature
import Reminders_Sample
import Reminders_SQLite
import Testing

@Suite(.dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)))
})
struct `Reminders root` {
    @Test func `the screen observes the database through its store`() async throws {
        let store = Store(initialState: Reminders.Feature.State()) { Reminders.Feature() }
        _ = Reminders.Screen(store: store)
        while store.overview.lists == nil { await Task.yield() }
        #expect(store.overview.lists?.map(\.list.title) == ["Personal", "Family"])
    }
}
