public import Interface_ComposableArchitecture
public import Reminder
public import Reminders
import Operation

extension Reminders {
    public var editing: Interface_ComposableArchitecture.Editing<Reminder> {
        Interface_ComposableArchitecture.Editing(
            create: create.callAsFunction,
            update: update.callAsFunction,
            delete: delete.callAsFunction,
            blank: .discardNewDeleteExisting { $0.isBlank },
            ignoreUpdateFailure: { $0 as? Update.Error == .notFound }
        )
    }
}
