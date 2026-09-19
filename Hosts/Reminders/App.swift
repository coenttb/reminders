import ComposableArchitecture2
import Reminders
import Reminders_SwiftUI
import Reminders_Feature
import SwiftUI

@main struct Application: App {
    static let store: StoreOf<Reminders> = .live()

    var body: some Scene {
        WindowGroup { Reminders.Screen(store: Self.store) }
    }
}
