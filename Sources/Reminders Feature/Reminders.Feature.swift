public import ComposableArchitecture2
public import Dependencies
public import Interface_ComposableArchitecture
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

extension Reminders {
    // The app: the front screen (`read()` followed), the open page, and the sheet. Every action is a call on
    // the domain; navigation and presentation are state the views set. Calls ride `writes`.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public var overview = Observing<Reminders.Read>.State()
            public var listing: Reminders.Read.Page.Feature.State?
            public var destination: Requesting<Reminders.Lists.Create>.State?
            @StoreTaskID public var writes

            public init() {}
        }

        // The page's calls are this feature's calls; the sheet's are the `lists` child's.
        public typealias Action = Reminders.Call

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                // The page showing a deleted list is gone before the call runs.
                if case let .lists.delete(request) = action, state.listing?.list == request.id {
                    state.listing = nil
                }
            }
            .calling(reminders, id: \.writes)
            .ifLet(\.listing) { Reminders.Read.Page.Feature() }
            .ifLet(\.destination, action: \.lists) { Requesting(\.reminders.lists.create) }
            Scope(\.overview) { Observing(reminders.read) }
        }
    }
}
