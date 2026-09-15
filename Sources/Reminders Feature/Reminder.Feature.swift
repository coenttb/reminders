public import ComposableArchitecture2
public import Foundation
public import Reminders
public import Tagged

extension Reminder {
    /// The form editing one reminder, presented by `Lists.Feature` as a destination: the draft
    /// is its state; Save, Cancel, and the tag intents are decided by the parent, which writes
    /// the database and hands the accepted tags back into the draft.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminder.Feature

            public var reminder: Reminder
            /// The value the form opened with: the sheet asks before discarding a draft that
            /// differs, and a save writes only what differs.
            public let original: Reminder
            /// Whether the form creates the reminder or edits a stored one; the parent decides at presentation.
            public let isNew: Bool
            /// Tells this presentation of the form from any other: work started for a form that
            /// has closed, or for an earlier form on the same reminder, reports to nobody.
            public let session: UUID
            /// Why the last save did not happen; the draft stays, and Done tries again.
            public var failure: String?
            /// Whether a save is under way; Done is ignored until it has succeeded or failed.
            public var isSaving = false

            public init(reminder: Reminder, isNew: Bool, session: UUID) {
                self.reminder = reminder
                self.original = reminder
                self.isNew = isNew
                self.session = session
            }

            public var isDirty: Bool { reminder != original }

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
            case tagDeleted(Tag.ID)
            case tagRenamed(Tag.ID, String)
        }

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            Update { _, _ in }
        }
    }
}
