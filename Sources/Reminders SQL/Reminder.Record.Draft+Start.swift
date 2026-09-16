public import Foundation
public import Models
public import Reminder
public import Tagged

extension Reminder.Record.Draft {
    public static func start(in list: List<Reminder>.ID, created: Date) -> Self {
        Self(listID: list, created: created)
    }
}
