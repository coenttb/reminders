public import ComposableArchitecture2
public import Dependencies
public import Interface_ComposableArchitecture
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

extension Reminders {
    // The app: the front screen (`read()` observed), the open page, and the sheet. Calls ride `writes`.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public typealias Feature = Reminders.Feature

            public var overview = Observing<Reminders.Read.Operations.Call>.State(request: .init())
            public var listing: Reminders.Read.Page.Feature.State?
            public var destination: Destination.State?
            @StoreTaskID public var writes

            public init() {}
        }

        public enum Action {
            case addListButtonTapped
            case call(Reminders.Call)
            case destination(Destination.Action)
            case listDeleted(Models.List<Reminder>.ID)
            case listTapped(Models.List<Reminder>.ID)
            case listing(Reminders.Read.Page.Feature.Action)
            case overview(Observing<Reminders.Read.Operations.Call>.Action)
        }

        @Dependency(\.reminders) var reminders
        @Dependency(\.uuid) var uuid

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Features {
                ComposableArchitecture2.Update { state, action in
                    switch action {
                    case .addListButtonTapped:
                        let list = Models.List<Reminder>(id: Models.List<Reminder>.ID(uuid()))
                        state.destination = .list(.init(request: .init(list)))
                    case .destination(.list(.cancelButtonTapped)):
                        state.destination = nil
                    case let .listDeleted(id):
                        // Deleting a list is a call; the page showing it is gone before the call runs.
                        if state.listing?.list == id { state.listing = nil }
                        let replacement = Models.List<Reminder>.ID(uuid())
                        store.addTask(id: state.writes) {
                            await try store.send(.call(.lists(.delete(id, replacement: replacement))))?.value
                        }
                    case let .listTapped(id):
                        state.listing = Reminders.Read.Page.Feature.State(page: .list(id))
                    case .call, .destination, .listing, .overview:
                        break
                    }
                }
                ComposableArchitecture2.Scope(\.overview) { Observing(reminders.read.run) }
            }
            .calling(\.call, id: \.writes) { try await reminders($0) }
            .ifLet(\.listing) {
                Reminders.Read.Page.Feature()
            }
            .ifLet(\.destination) {
                Destination.body
            }
        }
    }
}
