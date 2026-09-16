public import Foundation
public import Reminder

extension Reminder.Due {
    public static func setting(_ due: Self?, date: Date?) -> Self? {
        date.map { Self($0, hasTime: due?.hasTime ?? false) }
    }
}
