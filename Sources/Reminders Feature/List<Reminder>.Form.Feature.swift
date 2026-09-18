public import ComposableArchitecture2
public import Dependencies
import Foundation
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency

extension Models.List<Reminder>.Form {
    // A sheet: the draft is saved as a whole, and the sheet dismisses itself.
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Models.List<Reminder>.Form.Feature

            public var draft: Models.List<Reminder>
            public var failure: String?
            public var isSaving = false

            public init(draft: Models.List<Reminder>) {
                self.draft = draft
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
                    guard !state.draft.isBlank, !state.isSaving else { break }
                    state.isSaving = true
                    let draft = state.draft
                    store.addTask {
                        do {
                            try await reminders.lists.create(draft)
                            try store.dismiss()
                        } catch is CancellationError {
                            throw CancellationError()
                        } catch {
                            try store.modify {
                                $0.failure = error.localizedDescription
                                $0.isSaving = false
                            }
                        }
                    }
                }
            }
        }
    }
}
