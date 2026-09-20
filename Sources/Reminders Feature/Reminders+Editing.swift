@_exported import Reminder
public import Interface_ComposableArchitecture
public import Reminders

@EditingPolicy
extension Reminders {
    public var editing: some EditingFeature {
        Editing(
            create: create,
            update: update,
            delete: delete,
            draft: \.draft,
            blank: .discardNewDeleteExisting(\.isBlank)
        )
    }
}
