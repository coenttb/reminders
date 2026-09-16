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
            listing: .init(
                client: .init(
                    fetch: unimplemented("\\.reminders.listing.client.fetch", placeholder: Listing.Page(selection: .filter(.all), preference: Preference()))
                )
            ),
            editor: .init(
                client: .init(
                    reminder: unimplemented("\\.reminders.editor.client.reminder", placeholder: nil),
                    start: unimplemented("\\.reminders.editor.client.start", placeholder: nil),
                    add: unimplemented("\\.reminders.editor.client.add", placeholder: false),
                    update: unimplemented("\\.reminders.editor.client.update", placeholder: false),
                    toggle: unimplemented("\\.reminders.editor.client.toggle", placeholder: nil),
                    delete: unimplemented("\\.reminders.editor.client.delete"),
                    move: unimplemented("\\.reminders.editor.client.move"),
                    deleteCompleted: unimplemented("\\.reminders.editor.client.deleteCompleted")
                )
            ),
            lists: .init(
                client: .init(
                    add: unimplemented("\\.reminders.lists.client.add"),
                    update: unimplemented("\\.reminders.lists.client.update", placeholder: false),
                    delete: unimplemented("\\.reminders.lists.client.delete"),
                    reorder: unimplemented("\\.reminders.lists.client.reorder")
                )
            ),
            tags: .init(
                client: .init(
                    add: unimplemented("\\.reminders.tags.client.add", placeholder: nil),
                    rename: unimplemented("\\.reminders.tags.client.rename", placeholder: nil),
                    delete: unimplemented("\\.reminders.tags.client.delete"),
                    suggest: unimplemented("\\.reminders.tags.client.suggest", placeholder: [])
                )
            ),
            preferences: .init(
                client: .init(
                    ordering: unimplemented("\\.reminders.preferences.client.ordering"),
                    toggleShowCompleted: unimplemented("\\.reminders.preferences.client.toggleShowCompleted")
                )
            )
        )
    }
}
