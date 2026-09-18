public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Interface_ComposableArchitecture
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

extension Reminders.Read.Page {
    // One page, `read(page:)` followed, with the row being edited in place. The database is the truth: a new
    // row is inserted before it is edited, and the editor writes its draft back when it leaves. The feature
    // observes and calls, nothing else; calls ride `writes`.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public var observing: Observing<Reminders.Read.Page>.State
            public var editing: Reminders.Update.Feature.State?
            @StoreTaskID public var writes

            public init(page filter: Reminders.Read.Filter) {
                self.observing = .init(page: filter)
            }

            public var list: Models.List<Reminder>.ID? {
                if case let .list(id) = observing.request.filter { id } else { nil }
            }

            // The draft stands in for its row until the page carries what was written.
            public var contents: Value {
                var page = observing.value ?? Value()
                if let editing, let index = page.rows.firstIndex(where: { $0.id == editing.id }) {
                    page.rows[index] = editing.reminder
                }
                return page
            }
        }

        public typealias Action = Reminders.Call

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Features {
                ComposableArchitecture2.Update { state, action in
                    // A deleted row's draft is dropped with it.
                    if case let .delete(request) = action, state.editing?.id == request.id {
                        state.editing = nil
                    }
                }
                ComposableArchitecture2.Scope(\.observing) { Observing(reminders.read) }
            }
            .calling(reminders, id: \.writes)
            .ifLet(\.editing, action: \.self) {
                Reminders.Update.Feature()
            }
        }
    }
}
