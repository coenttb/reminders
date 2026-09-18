public import CasePaths
public import ComposableArchitecture2
public import Dependencies
public import Interface_ComposableArchitecture
public import List
public import Operation
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

// The interface's Calls are the features' actions.

extension Reminders {
    // The app: the front screen (`read()` followed), the open page, and the sheet. The root's own actions are
    // calls on the domain; the page's and the sheet's are their own calls, kept apart so that each call is run
    // once, by the feature whose task id carries its outcome. Navigation and presentation are state the views
    // set. The root's calls ride `writes`.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public var summary = Observing<Reminders.Read.Run>.State(.init())
            public var page: Reminders.Read.Page.Feature.State?
            public var newList: Requesting<Reminders.Lists.Create.Run>.State?
            @StoreTaskID public var writes

            public init() {}
        }

        // The root's own calls, and the calls of the children that run their own: the page's on its `writes`, the
        // new-list sheet's on its `sending`. A child's call is that child's, not the root's, so the cases are the
        // feature tree, not the interface. The summary has no actions and needs no case.
        public enum Action: Calls {
            case call(Reminders.Call)
            case page(Reminders.Read.Page.Feature.Action)
            case newList(Requesting<Reminders.Lists.Create.Run>.Action)
        }

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Features {
                ComposableArchitecture2.Update { state, action in
                    // The page showing a deleted list is gone before the call runs.
                    if case let .call(.lists(.delete(request))) = action, state.page?.list == request.id {
                        state.page = nil
                    }
                }
                ComposableArchitecture2.Scope(\.summary) { Observing(reminders.read) }
            }
            .calling(\.call, reminders, id: \.writes)
            .ifLet(\.page) {
                Reminders.Read.Page.Feature()
            }
            .ifLet(\.newList) {
                Requesting(\.reminders.lists.create)
            }
        }
    }
}
