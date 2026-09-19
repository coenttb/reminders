import ComposableArchitecture2
import Dependencies
import DependenciesTestSupport
import Foundation
import Interface_ComposableArchitecture
import List
import Reminder
import Reminders
import Reminders_Dependency
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
    @Dependency(\.reminders) var reminders

    @Test func `the screen observes the database through its store`() async throws {
        let store = Store(initialState: Reminders.State()) { reminders }
        _ = Reminders.Screen(store: store)
        while store.summary.lists == nil { await Task.yield() }
        #expect(store.summary.lists?.map(\.list.title) == ["Personal", "Family"])
    }
}
