import Optic
@_exported import Reminder
public import Interface_ComposableArchitecture
public import Reminders

@Editor
extension Reminders {
    public var editing: some Editor {
        Editing(
            create: create,
            update: update,
            delete: delete,
            draft: \.draft,
            blank: .discardNewDeleteExisting(\.isBlank),
            commit: .dismiss,
            discard: .delete
        )
    }
}
