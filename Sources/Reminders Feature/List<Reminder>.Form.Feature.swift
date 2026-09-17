public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Foundation

extension Models.List<Reminder>.Form {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Models.List<Reminder>.Form.Feature

            public var draft: Models.List<Reminder>
            public let original: Models.List<Reminder>?
            public var failure: String?
            public var isSaving = false

            public init(draft: Models.List<Reminder>, original: Models.List<Reminder>?) {
                self.draft = draft
                self.original = original
            }

            public var isNew: Bool { original == nil }

            public var isDirty: Bool { original.map { draft != $0 } ?? true }

            public mutating func fail(_ reason: String) {
                failure = reason
                isSaving = false
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
                    let (draft, isNew) = (state.draft, state.isNew)
                    store.addTask {
                        try await attempt {
                            do {
                                try isNew ? reminders.lists.product.create(draft) : reminders.lists.product.update(draft)
                                try store.dismiss()
                            } catch Reminders.Error.notFound {
                                try store.modify { $0.fail("This list was deleted.") }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Models.List<Reminder>.Form.Feature {
    private func attempt(_ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try store.modify { $0.fail(error.localizedDescription) }
        }
    }
}
