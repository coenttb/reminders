public import Foundation
public import Organizing
public import Reminders
public import Tagged

extension Reminders.Reminder.Record.Draft {
    public static func start(in list: List<Reminder>.ID, created: Date) -> Self {
        Self(listID: list, created: created)
    }
}
