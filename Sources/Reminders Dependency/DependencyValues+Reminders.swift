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
                    search: unimplemented("\\.reminders.search.client.search", placeholder: Search.Contents()),
                    deleteCompleted: unimplemented("\\.reminders.search.client.deleteCompleted")
                )
            ),
            detail: .init(
                client: .init(
                    fetch: unimplemented("\\.reminders.detail.client.fetch", placeholder: nil),
                    setOrdering: unimplemented("\\.reminders.detail.client.setOrdering"),
                    toggleShowCompleted: unimplemented("\\.reminders.detail.client.toggleShowCompleted"),
                    clearCompleted: unimplemented("\\.reminders.detail.client.clearCompleted"),
                    move: unimplemented("\\.reminders.detail.client.move")
                )
            ),
            editor: .init(
                client: .init(
                    reminder: unimplemented("\\.reminders.editor.client.reminder", placeholder: nil),
                    start: unimplemented("\\.reminders.editor.client.start", placeholder: nil),
                    save: unimplemented("\\.reminders.editor.client.save", placeholder: false),
                    toggle: unimplemented("\\.reminders.editor.client.toggle", placeholder: nil),
                    delete: unimplemented("\\.reminders.editor.client.delete")
                )
            ),
            lists: .init(
                client: .init(
                    save: unimplemented("\\.reminders.lists.client.save", placeholder: false),
                    delete: unimplemented("\\.reminders.lists.client.delete"),
                    reorder: unimplemented("\\.reminders.lists.client.reorder")
                )
            ),
            tags: .init(
                client: .init(
                    add: unimplemented("\\.reminders.tags.client.add", placeholder: nil),
                    rename: unimplemented("\\.reminders.tags.client.rename", placeholder: nil),
                    delete: unimplemented("\\.reminders.tags.client.delete")
                )
            ),
            restoration: .init(
                client: .init(
                    current: unimplemented("\\.reminders.restoration.client.current", placeholder: Session()),
                    setFilter: unimplemented("\\.reminders.restoration.client.setFilter"),
                    setEditing: unimplemented("\\.reminders.restoration.client.setEditing")
                )
            )
        )
    }
}
