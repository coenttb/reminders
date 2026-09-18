public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Reminders_SQLite
public import SQLiteData
public import Tagged

extension Reminders.Read {
    // The front screen: the summary observed, with the intents that act on lists as a whole.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Read.Feature

            @DebugSnapshotIgnored @Fetch public var summary = Reminders.Summary()

            public init() {}
        }

        public enum Action {
            case listDeleted(Models.List<Reminder>.ID)
            case listTapped(Models.List<Reminder>.ID)
        }

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .listDeleted, .listTapped:
                    break
                }
            }
            .onChange(of: Reminders.Read.Request(), initial: true) { _, request, state in
                let summary = state.$summary
                store.addTask {
                    try await store.attempt { try await summary.load(request) }
                }
            }
        }
    }
}
