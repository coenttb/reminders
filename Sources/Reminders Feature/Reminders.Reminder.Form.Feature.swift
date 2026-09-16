public import ComposableArchitecture2
public import Dependencies
public import Organizing
public import Reminders
public import Reminders_Interface
public import Reminders_SQL
import Reminders_SQLite
public import SQLiteData
import Standard_Library_Extensions
public import Tagged

extension Reminders.Reminder.Form {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = Reminders.Reminder.Form.Feature

            public var draft: Reminder.Record.Draft
            public var tags: Set<Tag<Reminder>.ID>
            public let original: Reminder.Record.Row?
            public var failure: String?
            public var isSaving = false

            public init(draft: Reminder.Record.Draft, tags: Set<Tag<Reminder>.ID>, original: Reminder.Record.Row?) {
                self.draft = draft
                self.tags = tags
                self.original = original
            }

            public var isNew: Bool { original == nil }

            public var isDirty: Bool {
                original.map { draft != Reminder.Record.Draft($0.reminder) || tags != Set($0.tags.map(Tag<Reminder>.ID.init)) } ?? true
            }

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

        @Dependency(\.defaultDatabase) var database

        public init() {}

        public var body: some ComposableArchitecture2.FeatureProtocol<State, Action> {
            ComposableArchitecture2.Update { state, action in
                switch action {
                case .cancelButtonTapped:
                    break
                case .saveButtonTapped:
                    guard !state.draft.isBlank, !state.isSaving else { break }
                    state.isSaving = true
                    let (draft, tags, isNew) = (state.draft, state.tags, state.isNew)
                    store.addTask {
                        try await attempt {
                            let saved = try write { db in try Reminder.Record.save(draft, tags: tags, isNew: isNew, in: db) }
                            if saved == nil {
                                try store.modify { $0.fail("This reminder was deleted.") }
                            } else {
                                try store.dismiss()
                            }
                        }
                    }
                case let .tagAdded(title):
                    store.addTask {
                        try await attempt {
                            guard let tag = try write({ db in try Tag<Reminder>.Record.add(title, in: db) }) else { return }
                            try store.modify {
                                $0.tags.insert(tag)
                                $0.failure = nil
                            }
                        }
                    }
                case let .tagDeleted(id):
                    store.addTask {
                        try await attempt {
                            try write { db in try Tag<Reminder>.Record.delete(id).execute(db) }
                            try store.modify {
                                $0.tags.remove(id)
                                $0.failure = nil
                            }
                            try store.post(key: Reminders.Feature.TagDeleted.self, value: id)
                        }
                    }
                case let .tagRenamed(id, title):
                    store.addTask {
                        try await attempt {
                            guard let renamed = try write({ db in try Tag<Reminder>.Record.rename(id, to: title, in: db) }) else { return }
                            try store.modify {
                                $0.tags.replace(id, with: renamed)
                                $0.failure = nil
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Reminders.Reminder.Form.Feature {
    private func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }

    /// Runs a task and lands its failure on the form.
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
