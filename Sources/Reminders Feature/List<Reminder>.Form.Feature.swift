public import ComposableArchitecture2
public import Dependencies
public import Models
public import Reminder
public import Reminders
public import Reminders_SQL
public import SQLiteData
import Foundation

extension Models.List<Reminder>.Form {
    @ComposableArchitecture2.Feature public struct Feature {
        public struct State: Sendable {
            public typealias Feature = List<Reminder>.Form.Feature

            public var draft: List<Reminder>.Record.Draft
            public let original: List<Reminder>.Record?
            public var failure: String?
            public var isSaving = false

            public init(draft: List<Reminder>.Record.Draft, original: List<Reminder>.Record?) {
                self.draft = draft
                self.original = original
            }

            public var isNew: Bool { original == nil }

            public var isDirty: Bool { original.map { draft != List<Reminder>.Record.Draft($0) } ?? true }

            public mutating func fail(_ reason: String) {
                failure = reason
                isSaving = false
            }
        }

        public enum Action {
            case cancelButtonTapped
            case saveButtonTapped
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
                    let (draft, isNew) = (state.draft, state.isNew)
                    store.addTask {
                        try await attempt {
                            let saved = try write { db in
                                if isNew {
                                    let inserted = List<Reminder>.Record.insert { draft }
                                    guard let id = try inserted.returning(\.id).fetchOne(db) else { return false }
                                    try List<Reminder>.Record.placeLast(id).execute(db)
                                    return true
                                }
                                guard let id = draft.id, try List<Reminder>.Record.find(id).fetchCount(db) > 0 else { return false }
                                try List<Reminder>.Record.save(draft).execute(db)
                                return true
                            }
                            if saved {
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
    private func write<T>(_ body: (Database) throws -> T) throws -> T { try database.write(body) }

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
