public import Dependencies
public import Reminders

extension DependencyValues {
    public var reminders: Reminders {
        get { self[Reminders.self] }
        set { self[Reminders.self] = newValue }
    }
}

extension Reminders: TestDependencyKey {
    public static var testValue: Reminders {
        Reminders(
            overview: .init(
                client: .init(
                    fetch: unimplemented("\\.reminders.overview.client.fetch", placeholder: Overview.Contents())
                )
            ),
            search: .init(
                client: .init(
                    search: unimplemented("\\.reminders.search.client.search", placeholder: Search.Contents())
                )
            ),
            detail: .init(
                client: .init(
                    fetch: unimplemented("\\.reminders.detail.client.fetch", placeholder: nil)
                )
            ),
            pending: .init(
                client: .init(
                    fetch: unimplemented("\\.reminders.pending.client.fetch", placeholder: [])
                )
            )
        )
    }
}
