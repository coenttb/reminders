public import CasePaths
public import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import Reminders
public import Operation

// The application declares only its navigation and presentation policy.
@FeatureExtension
extension Reminders: FeatureProtocol {
    public struct State {
        public var summary = Observing<Reminders.Read.Run>.State(.init())
        public var page: Reminders.Page.State?
        public var newList: Requesting<Reminders.Lists.Create.Run>.State?
        @StoreTaskID public var writes

        public init() {}
    }

    // The root's own calls, and the calls of the children that run their own: the page's on its `writes`, the
    // new-list sheet's on its `sending`. A child's call is that child's, not the root's, so the cases are the
    // feature tree, not the interface. The summary has no actions and needs no case.
    public enum Action: Calls {
        case call(Reminders.Call)
        case page(Reminders.Page.Action)
        case newList(Requesting<Reminders.Lists.Create.Run>.Action)
    }

    public var body: some Feature {
        Features {
            ComposableArchitecture2.Update { state, action in
                // The page showing a deleted list is gone before the call runs.
                if case let .call(.lists(.delete(request))) = action, state.page?.list == request.id {
                    state.page = nil
                }
            }
            Scope(\.summary) { Observing(self.read) }
        }
        .calling(\.call, self, id: \.writes)
        .ifLet(\.page) {
            self.page
        }
        .ifLet(\.newList) {
            Requesting(self.lists.create)
        }
    }
}
