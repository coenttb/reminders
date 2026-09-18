public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

extension Reminders {
    // The app: the front screen, the open page, and the sheet.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public typealias Feature = Reminders.Feature

            public var overview = Reminders.Read.Feature.State()
            public var listing: Reminders.Read.Page.Feature.State?
            public var destination: Destination.State?
            @StoreTaskID public var writes

            public init() {}
        }

        public enum Action {
            case addListButtonTapped
            case destination(Destination.Action)
            case listing(Reminders.Read.Page.Feature.Action)
            case overview(Reminders.Read.Feature.Action)
        }

        @Dependency(\.reminders) var reminders
        @Dependency(\.uuid) var uuid

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Features {
                ComposableArchitecture2.Update { state, action in
                    switch action {
                    case .addListButtonTapped:
                        state.destination = .list(Reminders.Lists.Create.Feature.State(list: Models.List<Reminder>(id: Models.List<Reminder>.ID(uuid()))))
                    case .destination(.list(.cancelButtonTapped)):
                        state.destination = nil
                    case .destination:
                        break
                    case let .overview(.listTapped(id)):
                        state.listing = Reminders.Read.Page.Feature.State(page: .list(id))
                    case let .overview(.listDeleted(id)):
                        let replacement = Models.List<Reminder>.ID(uuid())
                        store.addTask(id: state.writes) {
                            try await reminders.lists.delete(id, replacement: replacement)
                            try store.modify { if $0.listing?.request.filter == .list(id) { $0.listing = nil } }
                        }
                    case .listing, .overview:
                        break
                    }
                }
                ComposableArchitecture2.Scope(\.overview) { Reminders.Read.Feature() }
            }
            .ifLet(\.listing) {
                Reminders.Read.Page.Feature()
            }
            .ifLet(\.destination) {
                Destination.body
            }
        }
    }
}
