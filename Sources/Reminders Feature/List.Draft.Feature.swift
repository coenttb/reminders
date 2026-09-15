public import ComposableArchitecture2
public import Foundation
public import Organizing

extension List {
    /// The sheet's draft of one list; `Draft.Feature` is the form over it.
    public enum Draft {}
}

extension List.Draft {
    /// The form editing one list, presented by `Reminder.Feature` as a destination: the draft
    /// is its state; Save and Cancel are decided by the parent, which reads the draft back.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = List.Draft.Feature

            public var list: List
            public let original: List
            /// Whether the form creates the list or edits a stored one; the parent decides at presentation.
            public let isNew: Bool
            /// Tells this presentation of the form from any other: work started for a form that
            /// has closed, or for an earlier form on the same list, reports to nobody.
            public let session: UUID
            /// Why the last save did not happen; the draft stays, and Done tries again.
            public var failure: String?
            /// Whether a save is under way; Done is ignored until it has succeeded or failed.
            public var isSaving = false

            public init(list: List, isNew: Bool, session: UUID) {
                self.list = list
                self.original = list
                self.isNew = isNew
                self.session = session
            }

            public var isDirty: Bool { list != original }

            /// The save did not happen: the reason is shown and Done is enabled again.
            public mutating func fail(_ reason: String) {
                failure = reason
                isSaving = false
            }
        }

        public enum Action {
            case cancelButtonTapped
            case saveButtonTapped
        }

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            Update { _, _ in }
        }
    }
}
