public import ComposableArchitecture2
public import Reminders
public import Tagged

extension Reminder {
    /// The form editing one reminder, presented by `Lists.Feature` as a destination: the draft
    /// is its state; Save, Cancel, and the tag intents are decided by the parent, which owns
    /// the tags and writes the accepted ones back into the draft.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminder.Feature

            public var reminder: Reminder
            /// The value the form opened with; the sheet asks before discarding a draft that differs.
            public let original: Reminder
            /// Whether the form creates the reminder or edits one the lists hold; the parent decides at presentation.
            public let isNew: Bool

            public init(reminder: Reminder, isNew: Bool) {
                self.reminder = reminder
                self.original = reminder
                self.isNew = isNew
            }

            public var isDirty: Bool { reminder != original }
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
