public import Reminders
public import Foundation
public import Reminder

extension Reminder.Due {
    public static func applying(_ time: Reminder.Editor.Preset.Time?, to due: Self?, at now: Date, calendar: Calendar) -> Self? {
        let day = due?.date ?? now
        return time.map { .moment(calendar.date(bySettingHour: $0.hour, minute: 0, second: 0, of: day) ?? day) }
            ?? due.map { .day(calendar.startOfDay(for: $0.date)) }
    }
}
