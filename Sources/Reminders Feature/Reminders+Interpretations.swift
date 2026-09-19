import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import List
public import Reminder
public import Reminders
import Operation
public import Tagged

// Relationships between existing values, not new domain types or operation signatures.
extension Reminder: EditableRecord {}
extension Reminders.Read.Page.Value: ListingValue {}

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

// A filtered reminder query has a list only for the list-filter case. This meaning
// belongs to this domain; a generic listing does not infer it from names or types.
extension Listing.State where Symbol == Reminders.Read.Page.Run, Call == Reminders.Call {
    public var list: List<Reminder>.ID? {
        switch contents.request.filter {
        case let .list(id): id
        case .all: nil
        }
    }
}
