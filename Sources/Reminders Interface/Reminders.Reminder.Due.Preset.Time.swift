import Foundation
public import Reminders

extension Reminders.Reminder.Due.Preset {
    public enum Time: Int, CaseIterable, Hashable, Sendable {
        case morning = 9, midday = 12, afternoon = 15, evening = 18, night = 21

        public var hour: Int { rawValue }
    }
}
