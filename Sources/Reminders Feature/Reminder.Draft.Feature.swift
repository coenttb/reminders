public import ComposableArchitecture2
public import Foundation
public import Organizing
public import Reminders
public import Tagged

extension Reminder {
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
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminder.Draft.Feature

            public var draft: Reminder.Draft
            public var failure: String?
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
