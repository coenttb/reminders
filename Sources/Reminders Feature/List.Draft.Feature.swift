public import ComposableArchitecture2
public import Foundation
public import Organizing

extension List {
    /// The sheet's draft of one list: what is being typed, what the form opened with, whether
    /// the form creates the list or edits a stored one, and a session telling this
    /// presentation from any other.
    public struct Draft: Hashable, Sendable {
        public var list: List
        public let original: List
        public let isNew: Bool
        public let session: UUID

        public init(_ list: List, isNew: Bool, session: UUID) {
            self.list = list
            self.original = list
            self.isNew = isNew
            self.session = session
        }

        public var isDirty: Bool { list != original }
    }
}

extension List.Draft {
    /// The form over a draft, presented by `Reminder.Feature` as a destination: Save and
    /// Cancel are decided by the parent, which reads the draft back.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = List.Draft.Feature

            public var draft: List.Draft
            /// Why the last save did not happen; the draft stays, and Done tries again.
            public var failure: String?
            /// Whether a save is under way; Done is ignored until it has succeeded or failed.
            public var isSaving = false

            public init(list: List, isNew: Bool, session: UUID) {
                draft = List.Draft(list, isNew: isNew, session: session)
            }

            public var list: List {
                get { draft.list }
                set { draft.list = newValue }
            }
            public var original: List { draft.original }
            public var isNew: Bool { draft.isNew }
            public var session: UUID { draft.session }
            public var isDirty: Bool { draft.isDirty }

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
