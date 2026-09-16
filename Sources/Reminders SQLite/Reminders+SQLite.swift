public import Dependencies
public import Reminders
public import Reminders_Dependency
public import SQLiteData

extension Reminders {
    public static func sqlite(_ database: any DatabaseReader) -> Reminders {
        Reminders(
            overview: Overview(client: Overview.Client { request in try await database.read(request.fetch) }),
            search: Search(client: Search.Client { request in try await database.read(request.fetch) }),
            detail: Filter.Detail(client: Filter.Detail.Client { request in try await database.read(request.fetch) }),
            pending: Pending(client: Pending.Client { request in try await database.read(request.fetch) })
        )
    }
}

extension Reminders: DependencyKey {
    public static var liveValue: Reminders {
        @Dependency(\.defaultDatabase) var database
        return .sqlite(database)
    }
}
