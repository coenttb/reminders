import ComposableArchitecture2
import Reminders
import Reminders_App
import Reminders_Feature
import SwiftUI

/// The host: one scene around the application layer in `Reminders App`.
@main struct Application: App {
    /// The root store, held once for the process as the Point-Free Way has it.
    static let store = Reminder.Feature.live()

    var body: some Scene {
        WindowGroup { Root(store: Self.store) }
    }
}
