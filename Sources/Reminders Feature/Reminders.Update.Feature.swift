public import ComposableArchitecture2
public import Foundation
public import Reminder
public import Reminders

extension Reminders.Update {
    // One row being edited in place: the draft that `update` will be called with. The page it belongs to
    // commits it when the session ends.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Hashable, Sendable {
            public typealias Feature = Reminders.Update.Feature

            public var draft: Reminder
            public var original: Reminder
            // Each editing session has its own identity, so a stale task cannot end a newer session.
            public let session: UUID

            public init(_ reminder: Reminder, session: UUID) {
                self.draft = reminder
                self.original = reminder
                self.session = session
            }

            public var id: Reminder.ID { original.id }

            public var isSaved: Bool { draft == original }
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
