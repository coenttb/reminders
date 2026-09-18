public import CasePaths
public import ComposableArchitecture2
public import Dependencies
public import Interface_ComposableArchitecture
public import Models
public import Operation
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

// The interface's Calls are the features' actions.
extension Reminders.Call: CasePathable {}
extension Reminders.Lists.Call: CasePathable {}

extension Reminders {
    // The app: the front screen (`read()` followed), the open page, and the sheet. The root's own actions are
    // calls on the domain; the page's and the sheet's are their own calls, kept apart so that each call is run
    // once, by the feature whose task id carries its outcome. Navigation and presentation are state the views
    // set. The root's calls ride `writes`.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public var overview = Observing<Reminders.Read.Run>.State(.init())
            public var listing: Reminders.Read.Page.Feature.State?
            public var destination: Requesting<Reminders.Lists.Create>.State?
            @StoreTaskID public var writes

            public init() {}
        }

        public enum Action {
            case call(Reminders.Call)
            case destination(Requesting<Reminders.Lists.Create>.Action)
            case listing(Reminders.Read.Page.Feature.Action)
            case overview(Observing<Reminders.Read.Run>.Action)
        }

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Features {
                ComposableArchitecture2.Update { state, action in
                    // The page showing a deleted list is gone before the call runs.
                    if case let .call(.lists(.delete(request))) = action, state.listing?.list == request.id {
                        state.listing = nil
                    }
                }
                ComposableArchitecture2.Scope(\.overview) { Observing(reminders.read) }
            }
            .calling(\.call, reminders, id: \.writes)
            .ifLet(\.listing) {
                Reminders.Read.Page.Feature()
            }
            .ifLet(\.destination) {
                Requesting(\.reminders.lists)
            }
        }
    }
}
