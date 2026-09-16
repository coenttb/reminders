public import Foundation

extension Reminders.Search {
    public struct Client: Sendable {
        public var search: @Sendable (Request) async throws -> Contents
        public var deleteCompleted: @Sendable (Query, _ before: Date?) async throws -> Void

        public init(
            search: @escaping @Sendable (Request) async throws -> Contents,
            deleteCompleted: @escaping @Sendable (Query, _ before: Date?) async throws -> Void
        ) {
            self.search = search
            self.deleteCompleted = deleteCompleted
        }
    }
}
