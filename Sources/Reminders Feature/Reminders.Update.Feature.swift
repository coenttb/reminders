public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Reminder
public import Reminders
import Reminders_Dependency

extension Reminders.Update {
    // One row being edited in place: `update`'s request, drafted. The editor is presented for as long as the
    // row is being edited and writes the draft when it is dismissed; a blank row is dropped instead.
    @ComposableArchitecture2.Feature public struct Feature {
        // The state reads as the request it drafts: `state.title`, `state.completed`.
        @dynamicMemberLookup
        public struct State: Hashable, Sendable {
            public var request: Reminders.Update.Request
            public var original: Reminders.Update.Request

            public init(_ reminder: Reminder) {
                self.request = Request(reminder)
                self.original = Request(reminder)
            }

            public subscript<Member>(dynamicMember keyPath: WritableKeyPath<Reminders.Update.Request, Member>) -> Member {
                get { request[keyPath: keyPath] }
                set { request[keyPath: keyPath] = newValue }
            }

            public var id: Reminder.ID { original.id }

            public var isSaved: Bool { request == original }
        }

        public typealias Action = Reminders.Call

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some FeatureProtocol<State, Action> {
            EmptyFeature()
                // Leaving writes the draft whole; a blank row is dropped; a row that is gone stays gone.
                .onDismount {
                    if store.isBlank {
                        try await reminders.delete(store.id)
                    } else if !store.isSaved {
                        do {
                            try await reminders.update(store.request)
                        } catch Reminders.Update.Error.notFound {}
                    }
                }
        }
    }
}
