public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

extension Reminders.Read {
    // The front screen: `read()` observed, with the intents that act on lists as a whole.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public typealias Feature = Reminders.Read.Feature

            public var summary = Reminders.Summary()

            public init() {}
        }

        public enum Action {
            case listDeleted(Models.List<Reminder>.ID)
            case listTapped(Models.List<Reminder>.ID)
        }

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { _, action in
                switch action {
                case .listDeleted, .listTapped:
                    break
                }
            }
            .onMount { _ in
                store.addTask {
                    for try await summary in reminders.observe(Reminders.Read.Request()) {
                        try store.modify { $0.summary = summary }
                    }
                }
            }
        }
    }
}
