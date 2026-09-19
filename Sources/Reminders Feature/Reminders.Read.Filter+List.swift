// Aspirational syntax; see FEATURE-SYNTAX.md. Bridge support is not implemented.
public import List
public import Reminder
public import Reminders
public import Tagged

// This meaning belongs to the domain filter, not to a particular store encoding.
extension Reminders.Read.Filter {
    public var list: List<Reminder>.ID? {
        switch self {
        case let .list(id): id
        case .all: nil
        }
    }
}
