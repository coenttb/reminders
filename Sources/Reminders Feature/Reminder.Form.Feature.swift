public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
import Reminders_Dependency
import Standard_Library_Extensions
import Tagged
import Foundation

extension Reminder.Form {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminder.Form.Feature

            public var draft: Reminder
            public let original: Reminder?
            public var failure: String?
            public var isSaving = false

            public init(draft: Reminder, original: Reminder?) {
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
            case tagAdded(String)
            case tagDeleted(Tag<Reminder>)
            case tagRenamed(Tag<Reminder>, String)
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
                            if try isNew ? reminders.create.client(draft) : reminders.update.client(draft) {
                                try store.dismiss()
                            } else {
                                try store.modify { $0.fail("This reminder was deleted.") }
                            }
                        }
                    }
                case let .tagAdded(title):
                    store.addTask {
                        try await attempt {
                            guard let tag = try reminders.tags.create.client(title) else { return }
                            try store.modify {
                                $0.draft.tags.insert(tag)
                                $0.failure = nil
                            }
                        }
                    }
                case let .tagDeleted(id):
                    store.addTask {
                        try await attempt {
                            try reminders.tags.delete.client(id)
                            try store.modify {
                                $0.draft.tags.remove(id)
                                $0.failure = nil
                            }
                            try store.post(key: Reminders.Feature.TagDeleted.self, value: id)
                        }
                    }
                case let .tagRenamed(id, title):
                    store.addTask {
                        try await attempt {
                            guard let renamed = try reminders.tags.update.client(.init(tag: id, title: title)) else { return }
                            try store.modify {
                                $0.draft.tags.replace(id, with: renamed)
                                $0.failure = nil
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Reminder.Form.Feature {
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
