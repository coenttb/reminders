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
                fetch: .init(client: .init(unimplemented("\\.reminders.overview.fetch.client", placeholder: Overview.Fetch.Result())))
            ),
            listing: .init(
                fetch: .init(client: .init(unimplemented("\\.reminders.listing.fetch.client", placeholder: Listing.Fetch.Result(selection: .filter(.all), preference: Preference()))))
            ),
            editor: .init(
                find: .init(client: .init(unimplemented("\\.reminders.editor.find.client", placeholder: nil))),
                start: .init(client: .init(unimplemented("\\.reminders.editor.start.client", placeholder: nil))),
                add: .init(client: .init(unimplemented("\\.reminders.editor.add.client", placeholder: false))),
                update: .init(client: .init(unimplemented("\\.reminders.editor.update.client", placeholder: false))),
                toggle: .init(client: .init(unimplemented("\\.reminders.editor.toggle.client", placeholder: nil))),
                delete: .init(client: .init(unimplemented("\\.reminders.editor.delete.client"))),
                move: .init(client: .init(unimplemented("\\.reminders.editor.move.client"))),
                deleteCompleted: .init(client: .init(unimplemented("\\.reminders.editor.deleteCompleted.client")))
            ),
            lists: .init(
                add: .init(client: .init(unimplemented("\\.reminders.lists.add.client"))),
                update: .init(client: .init(unimplemented("\\.reminders.lists.update.client", placeholder: false))),
                delete: .init(client: .init(unimplemented("\\.reminders.lists.delete.client"))),
                reorder: .init(client: .init(unimplemented("\\.reminders.lists.reorder.client")))
            ),
            tags: .init(
                add: .init(client: .init(unimplemented("\\.reminders.tags.add.client", placeholder: nil))),
                rename: .init(client: .init(unimplemented("\\.reminders.tags.rename.client", placeholder: nil))),
                delete: .init(client: .init(unimplemented("\\.reminders.tags.delete.client"))),
                suggest: .init(client: .init(unimplemented("\\.reminders.tags.suggest.client", placeholder: [])))
            ),
            preferences: .init(
                ordering: .init(client: .init(unimplemented("\\.reminders.preferences.ordering.client"))),
                toggleShowCompleted: .init(client: .init(unimplemented("\\.reminders.preferences.toggleShowCompleted.client")))
            )
        )
    }
}
