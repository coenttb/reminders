public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
public import Reminders_Dependency
import Foundation

extension Models.List<Reminder>.Form {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = List<Reminder>.Form.Feature

            public var draft: List<Reminder>
            public let original: List<Reminder>?
            public var failure: String?
            public var isSaving = false

            public init(draft: List<Reminder>, original: List<Reminder>?) {
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
                            if try await reminders.lists.client.save(draft, isNew) {
                                try store.dismiss()
                            } else {
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
