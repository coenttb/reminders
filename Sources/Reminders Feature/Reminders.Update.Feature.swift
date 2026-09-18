public import ComposableArchitecture2
public import Foundation
public import Reminder
public import Reminders

extension Reminders.Update {
    // One row being edited in place: `update`'s request, drafted. The page it belongs to commits it when the
    // session ends.
    @ComposableArchitecture2.Feature public struct Feature {
        // The state reads as the request it drafts: `state.title`, `state.completed`.
        @dynamicMemberLookup
        public struct State: Hashable, Sendable {
            public var request: Reminders.Update.Request
            public var original: Reminders.Update.Request
            // Each editing session has its own identity, so a stale task cannot end a newer session.
            public let session: UUID

            public init(_ reminder: Reminder, session: UUID) {
                self.request = Request(reminder)
                self.original = Request(reminder)
                self.session = session
            }

            public subscript<Member>(dynamicMember keyPath: WritableKeyPath<Reminders.Update.Request, Member>) -> Member {
                get { request[keyPath: keyPath] }
                set { request[keyPath: keyPath] = newValue }
            }

            public var id: Reminder.ID { original.id }

            public var isSaved: Bool { request == original }
        }

        public enum Action {
            case completeButtonTapped
            case titleSubmitted
        }

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { _, action in
                switch action {
                case .completeButtonTapped, .titleSubmitted:
                    break
                }
            }
        }
    }
}
