import ComposableArchitecture2
public import Interface_ComposableArchitecture
public import List
public import Reminder
public import Reminders
public import Operation
public import Tagged

// Relationships between existing values, not new domain types or operation signatures.
extension Reminder: EditableRecord {}
extension Reminders.Read.Page.Value: ListingValue {}

extension Reminders {
    public typealias Page = Listing<Read.Page.Run, Call>
    public typealias Editing = Interface_ComposableArchitecture.Editing<Reminder>

    public var page: Page {
        Page(
            read.page,
            commands: self,
            editing: editing,
            deleting: \.delete?.id
        )
    }

    public var editing: Editing {
        Editing(
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
