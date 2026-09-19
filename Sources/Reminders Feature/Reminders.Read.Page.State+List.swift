public import Interface_ComposableArchitecture
public import List
public import Reminder
public import Reminders
import Operation
public import Tagged

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
