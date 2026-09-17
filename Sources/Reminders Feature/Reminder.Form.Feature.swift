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
                            do {
                                _ = try isNew ? reminders.create(draft, below: nil) : reminders.update(draft)
                                try store.dismiss()
                            } catch Reminders.Error.notFound {
                                try store.modify { $0.fail("This reminder was deleted.") }
                            }
                        }
                    }
                case let .tagAdded(title):
                    store.addTask {
                        try await attempt {
                            guard let tag = try create(tag: title) else { return }
                            try store.modify {
                                $0.draft.tags.insert(tag)
                                $0.failure = nil
                            }
                        }
                    }
                case let .tagDeleted(id):
                    store.addTask {
                        try await attempt {
                            try reminders.tags.delete(id)
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
                            guard let renamed = try rename(tag: id, to: title) else { return }
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
    private func create(tag title: String) throws -> Tag<Reminder>? {
        do {
            return try reminders.tags.create(title)
        } catch Reminders.Error.blank {
            return nil
        }
    }

    private func rename(tag: Tag<Reminder>, to title: String) throws -> Tag<Reminder>? {
        do {
            return try reminders.tags.update(tag, title: title)
        } catch Reminders.Error.blank, Reminders.Error.notFound {
            return nil
        }
    }

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
