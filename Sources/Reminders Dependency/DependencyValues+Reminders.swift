public import Dependencies
import Models
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
                    fetch: .init(unimplemented("\\.reminders.overview.client.fetch", placeholder: Overview.Fetch.Result()))
                )
            ),
            listing: .init(
                client: .init(
                    fetch: .init(unimplemented("\\.reminders.listing.client.fetch", placeholder: Listing.Fetch.Result(selection: .filter(.all), preference: Preference())))
                )
            ),
            editor: .init(
                client: .init(
                    find: .init(unimplemented("\\.reminders.editor.client.find", placeholder: nil)),
                    start: .init(unimplemented("\\.reminders.editor.client.start", placeholder: nil)),
                    add: .init(unimplemented("\\.reminders.editor.client.add", placeholder: false)),
                    update: .init(unimplemented("\\.reminders.editor.client.update", placeholder: false)),
                    toggle: .init(unimplemented("\\.reminders.editor.client.toggle", placeholder: nil)),
                    delete: .init(unimplemented("\\.reminders.editor.client.delete")),
                    move: .init(unimplemented("\\.reminders.editor.client.move")),
                    deleteCompleted: .init(unimplemented("\\.reminders.editor.client.deleteCompleted"))
                )
            ),
            lists: .init(
                client: .init(
                    add: .init(unimplemented("\\.reminders.lists.client.add")),
                    update: .init(unimplemented("\\.reminders.lists.client.update", placeholder: false)),
                    delete: .init(unimplemented("\\.reminders.lists.client.delete")),
                    reorder: .init(unimplemented("\\.reminders.lists.client.reorder"))
                )
            ),
            tags: .init(
                client: .init(
                    add: .init(unimplemented("\\.reminders.tags.client.add", placeholder: nil)),
                    rename: .init(unimplemented("\\.reminders.tags.client.rename", placeholder: nil)),
                    delete: .init(unimplemented("\\.reminders.tags.client.delete")),
                    suggest: .init(unimplemented("\\.reminders.tags.client.suggest", placeholder: []))
                )
            ),
            preferences: .init(
                client: .init(
                    ordering: .init(unimplemented("\\.reminders.preferences.client.ordering")),
                    toggleShowCompleted: .init(unimplemented("\\.reminders.preferences.client.toggleShowCompleted"))
                )
            )
        )
    }
}
