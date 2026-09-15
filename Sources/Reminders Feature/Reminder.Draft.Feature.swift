public import ComposableArchitecture2
public import Foundation
public import Organizing
public import Reminders
public import Tagged

extension Reminder {
    /// The sheet's draft of one reminder: what is being typed, what the form opened with (the
    /// sheet asks before discarding a draft that differs, and a save writes only what differs),
    /// whether the form creates the reminder or edits a stored one, and a session telling this
    /// presentation from any other: work started for a form that has closed reports to nobody.
    public struct Draft: Hashable, Sendable {
        public var reminder: Reminder
        public let original: Reminder
        public let isNew: Bool
        public let session: UUID

        public init(_ reminder: Reminder, isNew: Bool, session: UUID) {
            self.reminder = reminder
            self.original = reminder
            self.isNew = isNew
            self.session = session
        }

        public var isDirty: Bool { reminder != original }
    }
}

extension Reminder.Draft {
    /// The form over a draft, presented by `Reminder.Feature` as a destination: Save, Cancel,
    /// and the tag intents are decided by the parent, which writes the database and hands the
    /// accepted tags back into the draft.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminder.Draft.Feature

            public var draft: Reminder.Draft
            /// Why the last save did not happen; the draft stays, and Done tries again.
            public var failure: String?
            /// Whether a save is under way; Done is ignored until it has succeeded or failed.
            public var isSaving = false

            public init(reminder: Reminder, isNew: Bool, session: UUID) {
                draft = Reminder.Draft(reminder, isNew: isNew, session: session)
            }

            public var reminder: Reminder {
                get { draft.reminder }
                set { draft.reminder = newValue }
            }
            public var original: Reminder { draft.original }
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
            case tagAdded(String)
            case tagDeleted(Tag<Reminder>.ID)
            case tagRenamed(Tag<Reminder>.ID, String)
        }

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            Update { _, _ in }
        }
    }
}
