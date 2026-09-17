public import Foundation
public import Reminder
public import Tagged

// A screen whose rows can be completed: a tap starts a grace period, a second tap takes it back.
public protocol Gracing {
    var grace: [Reminder.ID: UUID] { get set }
    func isCompleted(_ id: Reminder.ID) -> Bool?
    mutating func finished(_ id: Reminder.ID, completed: Bool)
}

extension Gracing {
    public var gracing: Set<Reminder.ID> { Set(grace.keys) }
}
