public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Operation
public import Reminder
public import Reminders
import Reminders_Dependency

extension Reminders.Update {
    // One row being edited in place: a draft, and the row it came from when it is not new. The editor is presented
    // for as long as the row is being edited and writes when it is dismissed: a new draft is created, a changed
    // row is updated, a blank one is dropped.
    @ComposableArchitecture2.Feature public struct Feature {
        // The state reads as the draft it edits: `state.title`, `state.completed`.
        @dynamicMemberLookup
        public struct State: Hashable, Sendable {
            public var draft: Reminder.Draft
            public let original: Reminder?

            public init(_ draft: Reminder.Draft) {
                self.draft = draft
                self.original = nil
            }

            public init(_ reminder: Reminder) {
                self.draft = reminder.draft
                self.original = reminder
            }

            public subscript<Member>(dynamicMember keyPath: WritableKeyPath<Reminder.Draft, Member>) -> Member {
                get { draft[keyPath: keyPath] }
                set { draft[keyPath: keyPath] = newValue }
            }

            public var id: Reminder.ID? { original?.id }

            public var isSaved: Bool { original?.draft == draft }
        }

        // The editor has no actions: its draft is state, and leaving is what writes.
        public typealias Action = Never

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.EmptyFeature()
                // Leaving writes: a row that is gone stays gone.
                .onDismount {
                    let state = store.state
                    if let original = state.original {
                        if state.draft.isBlank {
                            try await reminders.delete(original.id)
                        } else if !state.isSaved {
                            do {
                                try await reminders.update(Reminder(id: original.id, state.draft, created: original.created))
                            } catch Reminders.Update.Error.notFound {}
                        }
                    } else if !state.draft.isBlank {
                        _ = try await reminders.create(state.draft)
                    }
                }
        }
    }
}
