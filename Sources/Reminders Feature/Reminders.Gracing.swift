public import Foundation
public import Reminder
public import Reminders
public import Tagged

// A screen whose rows have pending work: a tap starts a grace period, a second tap takes it back, a tap
// on a completed row reopens it, and a swipe deletes it. The state carries what is pending because the
// tasks of one action replace each other: a restarted task works through the state and drops nothing.
public protocol Gracing {
    var grace: [Reminder.ID: UUID] { get set }
    var reopening: Set<Reminder.ID> { get set }
    var deleting: Set<Reminder.ID> { get set }
    func isCompleted(_ id: Reminder.ID) -> Bool?
    mutating func finished(_ id: Reminder.ID, completed: Bool)
}

extension Gracing {
    public var gracing: Set<Reminder.ID> { Set(grace.keys) }

    // A destructive swipe takes its row out at once, before the database says so.
    public func shown(_ page: Reminders.Page) -> Reminders.Page {
        var page = page
        page.rows.removeAll { deleting.contains($0.id) }
        return page
    }

    public func isShownCompleted(_ reminder: Reminder) -> Bool {
        grace[reminder.id] != nil || (reminder.completed && !reopening.contains(reminder.id))
    }
}
