public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency

extension Reminders.Lists.Create {
    // A sheet: the list that `lists.create` will be called with, saved whole; the sheet dismisses itself.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State {
            public typealias Feature = Reminders.Lists.Create.Feature

            public var list: Models.List<Reminder>
            @StoreTaskID public var saving

            public init(list: Models.List<Reminder>) {
                self.list = list
            }
        }

        public enum Action {
            case cancelButtonTapped
            case saveButtonTapped
        }

        @Dependency(\.reminders) var reminders

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .cancelButtonTapped:
                    break
                case .saveButtonTapped:
                    guard !state.list.isBlank, !state.saving.isRunning else { break }
                    let list = state.list
                    store.addTask(id: state.saving) {
                        try await reminders.lists.create(list)
                        try store.dismiss()
                    }
                }
            }
        }
    }
}
