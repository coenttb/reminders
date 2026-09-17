public import Foundation
public import Reminder
public import Tagged

// A screen whose rows can be completed: a tap starts a grace period, a second tap takes it back, and a
// tap on a completed row reopens it.
public protocol Gracing {
    var grace: [Reminder.ID: UUID] { get set }
    var reopening: Set<Reminder.ID> { get set }
    func isCompleted(_ id: Reminder.ID) -> Bool?
    mutating func finished(_ id: Reminder.ID, completed: Bool)
}

extension Gracing {
    public var gracing: Set<Reminder.ID> { Set(grace.keys) }

    public func isShownCompleted(_ reminder: Reminder) -> Bool {
        grace[reminder.id] != nil || (reminder.completed && !reopening.contains(reminder.id))
    }
}
