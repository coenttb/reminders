public import ComposableArchitecture2
public import Dependencies
public import Foundation
public import Interface_ComposableArchitecture
public import List
public import Operation
public import Reminder
public import Reminders
import Reminders_Dependency
public import Tagged

extension Reminders.Read.Page {
    // One page, `read.page(filter:)` followed, with one row being edited in place — an existing row, or a draft that
    // becomes a row when its editor leaves. The feature observes and calls, nothing else: its actions are the
    // domain's calls, each run once here, on `writes`.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public var contents: Observing<Reminders.Read.Page.Run>.State
            public var editing: Reminders.Update.Feature.State?
            @StoreTaskID public var writes

            public init(_ filter: Reminders.Read.Filter) {
                self.contents = .init(filter)
            }

            public var list: List<Reminder>.ID? {
                if case let .list(id) = contents.request.filter { id } else { nil }
            }

            // The rows, with the draft of an existing row standing in for it until the page carries what was written.
            public var rows: [Reminder] {
                var rows = contents.rows ?? []
                if let editing, let original = editing.original, let index = rows.firstIndex(where: { $0.id == original.id }) {
                    rows[index] = Reminder(id: original.id, editing.draft, created: original.created)
                }
                return rows
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
                ComposableArchitecture2.Scope(\.contents) { Observing(reminders.read.page) }
            }
            .calling(reminders, id: \.writes)
            .ifLet(\.editing) {
                Reminders.Update.Feature()
            }
        }
    }
}
