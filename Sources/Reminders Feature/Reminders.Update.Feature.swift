public import ComposableArchitecture2
public import Foundation
public import Reminder
public import Reminders

extension Reminders.Update {
    // One row being edited in place: `update`'s request, drafted. The page it belongs to commits it when the
    // session ends.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Hashable, Sendable {
            public typealias Feature = Reminders.Update.Feature

            public var request: Reminders.Update.Run.Input
            public var original: Reminders.Update.Run.Input
            // Each editing session has its own identity, so a stale task cannot end a newer session.
            public let session: UUID

            public init(_ reminder: Reminder, session: UUID) {
                self.request = Run.Input(reminder)
                self.original = Run.Input(reminder)
                self.session = session
            }

            public var id: Reminder.ID { original.reminder.id }

            public var isBlank: Bool { request.reminder.isBlank }

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
