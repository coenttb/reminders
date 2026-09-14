import ComposableArchitecture2
import Reminders
import Reminders_App
import Reminders_Feature
import SwiftUI

/// The host: one scene around the application layer in `Reminders App`.
@main struct Application: App {
    @State private var store = Lists.Feature.live()

    var body: some Scene {
        WindowGroup { Root(store: store) }
    }
}
