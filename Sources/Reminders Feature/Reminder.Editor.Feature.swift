public import ComposableArchitecture2
public import Foundation
public import Reminder

extension Reminder.Editor {
    // One row being edited in place. The draft is bound to directly; the parent listing commits it.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Hashable, Sendable {
            public typealias Feature = Reminder.Editor.Feature

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
