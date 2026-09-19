import ComposableArchitecture2
import Interface_ComposableArchitecture
import Dependencies
import DependenciesTestSupport
import Foundation
import List
import Reminder
import Reminders
import Reminders_Dependency
import Reminders_Feature
import Reminders_Sample
import Reminders_SQLite
import Reminders_SwiftUI
import SwiftUI
import Tagged
import Testing

@Suite(.dependencies {
    $0.uuid = .incrementing
    try $0.bootstrapDatabase(seeding: Reminders.sample(at: Date(timeIntervalSince1970: 1_234_567_890)))
})
struct `Reminders views` {
    @Dependency(\.reminders) var reminders

    @Test func `a row is built from a value; the page from a store`() {
        let reminder = Reminder(id: Reminder.ID(UUID()), list: List<Reminder>.ID(UUID()), title: "Milk", created: Date())
        _ = Reminder.Row.SwiftUI(reminder: reminder, complete: {}, delete: {}, edit: {})
        let store = Store(initialState: Reminders.Page.State(.all)) { reminders.page }
        _ = Reminders.Read.Page.SwiftUI(store: store, title: "All")
    }
}
