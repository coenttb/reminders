public import ComposableArchitecture2
public import Reminders

extension Reminder.List {
    /// The form editing one list, presented by `Lists.Feature` as a destination: the draft is
    /// its state; Save and Cancel are decided by the parent, which reads the draft back.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminder.List.Feature

            public var list: Reminder.List
            public let original: Reminder.List
            /// Whether the form creates the list or edits one the lists hold; the parent decides at presentation.
            public let isNew: Bool

            public init(list: Reminder.List, isNew: Bool) {
                self.list = list
                self.original = list
                self.isNew = isNew
            }

            public var isDirty: Bool { list != original }
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
