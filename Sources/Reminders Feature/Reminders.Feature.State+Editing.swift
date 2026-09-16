import Foundation
public import Reminder
public import Reminders
public import Tagged

extension Reminders.Feature.State {
    mutating func endEditing(_ session: UUID?) {
        guard let session, editing?.session == session else { return }
        editing = nil
    }
}

extension Reminders.Feature.State {
    public func isCompleted(_ id: Reminder.ID) -> Bool? {
        if editing?.id == id { return editing?.original.completed }
        if let row = detail?.rows.first(where: { $0.id == id }) { return row.completed }
        return results.sections.lazy.flatMap(\.rows).first { $0.id == id }?.completed
    }

    public var gracing: Set<Reminder.ID> { Set(grace.keys) }
}
