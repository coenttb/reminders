import Foundation
import FoundationEssentials_Extensions
import Models
import Reminder
import Reminders
import Reminders_Feature
import Testing

@Suite struct `Reminders editing rules` {
    let calendar = Calendar(identifier: .gregorian)

    @Test func `a time needs a date, a date can stand alone, and dropping the date drops the time`() throws {
        let now = try #require(Date(year: 2026, month: 9, day: 14, hour: 9, minute: 20, in: calendar))
        let nextHour = try #require(Date(year: 2026, month: 9, day: 14, hour: 10, in: calendar))
        var due: Reminder.Due? = nil
        due = Reminder.Due.setting(due, hasTime: true, at: now, calendar: calendar)
        #expect(due == .moment(nextHour))
        due = Reminder.Due.setting(due, date: nil)
        #expect(due == nil)
        let day = try #require(Date(year: 2026, month: 9, day: 20, in: calendar))
        due = Reminder.Due.setting(due, date: day)
        #expect(due == .day(day))
        due = Reminder.Due.setting(due, hasTime: true, at: now, calendar: calendar)
        #expect(due == Date(year: 2026, month: 9, day: 20, hour: 10, in: calendar).map(Reminder.Due.moment))
        let later = try #require(Date(year: 2026, month: 9, day: 22, in: calendar))
        due = Reminder.Due.setting(due, date: later)
        #expect(due == .moment(later))
        due = Reminder.Due.setting(due, hasTime: false, at: now, calendar: calendar)
        #expect(due == .day(later))
    }

    @Test func `date and time presets resolve against now`() throws {
        let now = try #require(Date(year: 2026, month: 9, day: 15, hour: 8, minute: 30, in: calendar))
        let tomorrow = try #require(Date(year: 2026, month: 9, day: 16, in: calendar))
        #expect(Reminder.Editor.Preset.today.date(at: now, calendar: calendar) == calendar.startOfDay(for: now))
        #expect(Reminder.Editor.Preset.date(for: .tomorrow, at: now, calendar: calendar) == tomorrow)
        #expect(calendar.component(.weekday, from: Reminder.Editor.Preset.nextWeekend.date(at: now, calendar: calendar)) == 7)
        let friday = try #require(Date(year: 2026, month: 9, day: 18, hour: 8, in: calendar))
        #expect(Reminder.Editor.Preset.nextWeekend.date(at: friday, calendar: calendar) == Date(year: 2026, month: 9, day: 26, in: calendar))
        #expect(calendar.component(.weekday, from: Reminder.Editor.Preset.nextWeek.date(at: now, calendar: calendar)) == 2)
        #expect(Reminder.Editor.Preset.Time.allCases.map(\.hour) == [9, 12, 15, 18, 21])
        var due: Reminder.Due? = nil
        due = Reminder.Due.applying(.evening, to: due, at: now, calendar: calendar)
        let evening = try #require(due)
        #expect(evening.hasTime && calendar.component(.hour, from: evening.date) == 18)
        due = Reminder.Due.applying(.tomorrow, to: due, at: now, calendar: calendar)
        let moved = try #require(due)
        #expect(calendar.isDate(moved.date, inSameDayAs: tomorrow) && calendar.component(.hour, from: moved.date) == 18 && moved.hasTime)
        due = Reminder.Due.applying(Reminder.Editor.Preset.Time?.none, to: due, at: now, calendar: calendar)
        #expect(due == .day(tomorrow))
        due = Reminder.Due.applying(Reminder.Editor.Preset?.none, to: due, at: now, calendar: calendar)
        #expect(due == nil)
    }
}
