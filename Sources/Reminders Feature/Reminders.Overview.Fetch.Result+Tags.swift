import Foundation
public import Models
public import Reminder
public import Reminders

extension Reminders.Overview.Fetch.Result {
    public var usedTags: [Tag<Reminder>] {
        tags.filter { $0.count > 0 }.map(\.tag).sorted { $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == .orderedAscending }
    }

    public var rankedTags: [Tag<Reminder>] { tags.map(\.tag) }

    public func list(_ id: List<Reminder>.ID) -> List<Reminder>? { lists.first { $0.id == id }?.list }
}
