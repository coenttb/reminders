import ComposableArchitecture2
import Reminders
import Reminders_App
import Reminders_Feature
import SwiftUI

@main struct Application: App {
    static let store: StoreOf<Reminders.Feature> = .live()

    var body: some Scene {
        WindowGroup { Reminders.Screen(store: Self.store) }
    }
}
