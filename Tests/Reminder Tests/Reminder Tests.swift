import Foundation
import FoundationEssentials_Extensions
import Organizing
import Reminder
import Testing
import Tagged

@Suite struct `Reminder rules` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)
    let list = List<Reminder>.ID(UUID())

    func reminder(_ title: String = "x", due: Reminder.Due? = nil) -> Reminder {
        Reminder(id: Reminder.ID(UUID()), list: list, title: title, due: due, created: now)
    }

    @Test func `only incomplete reminders before today are past due`() {
        var reminder = reminder("Call", due: .day(now.addingTimeInterval(-.day)))
        #expect(reminder.pastDue(at: now, calendar: calendar))
        reminder.completion = .completed
        #expect(!reminder.pastDue(at: now, calendar: calendar))
        reminder.completion = .incomplete
        reminder.due = .moment(now)
        #expect(!reminder.pastDue(at: now, calendar: calendar))
        #expect(!self.reminder().pastDue(at: now, calendar: calendar))
    }

    @Test func `a completion is incomplete or completed`() {
        var reminder = reminder()
        #expect(reminder.completion == .incomplete && !reminder.completed)
        reminder.completion = .completed
        #expect(reminder.completion == .completed && reminder.completed)
    }

    @Test func `a title of only whitespace is blank`() {
        #expect(reminder(" \n").isBlank)
        #expect(!reminder("Call").isBlank)
    }

    @Test func `a due date is a day or a moment`() throws {
        let date = try #require(Date(year: 2026, month: 9, day: 20, hour: 10, in: calendar))
        #expect(Reminder.Due.day(date).date == date && !Reminder.Due.day(date).hasTime)
        #expect(Reminder.Due.moment(date).date == date && Reminder.Due.moment(date).hasTime)
        #expect(Reminder.Due(date, hasTime: true) == .moment(date) && Reminder.Due(date, hasTime: false) == .day(date))
        var reminder = reminder(due: .moment(date))
        #expect(reminder.due?.date == date && reminder.due?.hasTime == true)
        reminder.set(hasTime: false, at: now, calendar: calendar)
        #expect(reminder.due == .day(date))
        reminder.set(due: nil)
        #expect(reminder.due == nil)
    }

    @Test func `a time needs a date, a date can stand alone, and dropping the date drops the time`() throws {
        let now = try #require(Date(year: 2026, month: 9, day: 14, hour: 9, minute: 20, in: calendar))
        let nextHour = try #require(Date(year: 2026, month: 9, day: 14, hour: 10, in: calendar))
        var reminder = reminder()
        reminder.set(hasTime: true, at: now, calendar: calendar)
        #expect(reminder.due == .moment(nextHour))
        reminder.set(due: nil)
        #expect(reminder.due == nil)
        let day = try #require(Date(year: 2026, month: 9, day: 20, in: calendar))
        reminder.set(due: day)
        #expect(reminder.due == .day(day))
        reminder.set(hasTime: true, at: now, calendar: calendar)
        #expect(reminder.due == Date(year: 2026, month: 9, day: 20, hour: 10, in: calendar).map(Reminder.Due.moment))
        let later = try #require(Date(year: 2026, month: 9, day: 22, in: calendar))
        reminder.set(due: later)
        #expect(reminder.due == .moment(later))
        reminder.set(hasTime: false, at: now, calendar: calendar)
        #expect(reminder.due == .day(later))
    }

    @Test func `date and time presets resolve against now`() throws {
        let now = try #require(Date(year: 2026, month: 9, day: 15, hour: 8, minute: 30, in: calendar))
        let tomorrow = try #require(Date(year: 2026, month: 9, day: 16, in: calendar))
        #expect(Reminder.Due.Preset.today.date(at: now, calendar: calendar) == calendar.startOfDay(for: now))
        #expect(Reminder.Due.Preset.date(for: .tomorrow, at: now, calendar: calendar) == tomorrow)
        #expect(calendar.component(.weekday, from: Reminder.Due.Preset.thisWeekend.date(at: now, calendar: calendar)) == 7)
        #expect(calendar.component(.weekday, from: Reminder.Due.Preset.nextWeek.date(at: now, calendar: calendar)) == 2)
        #expect(Reminder.Due.Preset.Time.allCases.map(\.hour) == [9, 12, 15, 18, 21])
        var reminder = reminder()
        reminder.set(timePreset: .evening, at: now, calendar: calendar)
        let evening = try #require(reminder.due)
        #expect(evening.hasTime && calendar.component(.hour, from: evening.date) == 18)
        reminder.set(datePreset: .tomorrow, at: now, calendar: calendar)
        let moved = try #require(reminder.due)
        #expect(calendar.isDate(moved.date, inSameDayAs: tomorrow) && calendar.component(.hour, from: moved.date) == 18 && moved.hasTime)
        reminder.set(timePreset: nil, at: now, calendar: calendar)
        #expect(reminder.due == .day(tomorrow))
        reminder.set(datePreset: nil, at: now, calendar: calendar)
        #expect(reminder.due == nil)
    }
}
