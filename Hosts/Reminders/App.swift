import ComposableArchitecture2
import Dependencies
import Reminders
import Reminders_Dependency
import Reminders_Sample
import Reminders_SQLite
import Reminders_SwiftUI
import Reminders_Feature
import SwiftUI

@main struct Application: App {
    static let store: StoreOf<Reminders> = {
        prepareDependencies {
            #if DEBUG
            try! $0.bootstrapDatabase(seeding: Reminders.sample(at: $0.date.now))
            #else
            try! $0.bootstrapDatabase()
            #endif
        }
        @Dependency(\.reminders) var reminders
        return Store(initialState: .init()) { reminders }
    }()

    var body: some Scene {
        WindowGroup { Reminders.View(store: Self.store) }
    }
}
