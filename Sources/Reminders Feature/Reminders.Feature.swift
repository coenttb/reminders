public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

extension Reminders {
    // The app: the front screen, the open list, the sheet, and the failure to show.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Feature

            public var overview = Reminders.Read.Feature.State()
            public var listing: Reminders.Listing.Feature.State?
            public var destination: Destination.State?
            public var failure: String?

            public init() {}
        }

        public enum Action {
            case addListButtonTapped
            case destination(Destination.Action)
            case listing(Reminders.Listing.Feature.Action)
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
                        state.destination = .list(Models.List<Reminder>.Form.Feature.State(draft: Models.List<Reminder>(id: Models.List<Reminder>.ID(uuid()))))
                    case .destination(.list(.cancelButtonTapped)):
                        state.destination = nil
                    case .destination:
                        break
                    case let .overview(.listTapped(id)):
                        state.listing = Reminders.Listing.Feature.State(filter: .list(id))
                    case let .overview(.listDeleted(id)):
                        let replacement = Models.List<Reminder>.ID(uuid())
                        store.addTask {
                            try await store.attempt {
                                try await reminders.lists.delete(id, replacement: replacement)
                                try store.modify { if $0.listing?.filter == .list(id) { $0.listing = nil } }
                            }
                        }
                    case .listing, .overview:
                        break
                    }
                }
                ComposableArchitecture2.Scope(\.overview) { Reminders.Read.Feature() }
            }
            .ifLet(\.listing) {
                Reminders.Listing.Feature()
            }
            .ifLet(\.destination) {
                Destination.body
            }
            .onEvent(Failed.self) { reason, state in
                state.failure = reason
            }
        }
    }
}
