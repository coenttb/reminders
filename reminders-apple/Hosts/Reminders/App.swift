import ComposableArchitecture2
import Reminders
import Reminders_App
import Reminders_Feature
import SwiftUI

@main struct Application: App {
    static let store = Reminder.Feature.live()

    var body: some Scene {
        WindowGroup { Root(store: Self.store) }
    }
}
