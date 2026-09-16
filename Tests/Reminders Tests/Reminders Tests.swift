import Foundation
import FoundationEssentials_Extensions
import Models
import Reminder
import Reminders
import Testing
import Tagged

@Suite struct `Reminders rules` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)
    let list = List<Reminder>.ID(UUID())

    func reminder(_ title: String = "x", due: Reminder.Due? = nil) -> Reminder {
        Reminder(id: Reminder.ID(UUID()), list: list, title: title, due: due, created: now)
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

    @Test func `a filter narrows and closes as its tags and list go`() {
        #expect(Reminders.Filter.tags(["car", "kids"]).removing(tag: "car") == .tags(["kids"]))
        #expect(Reminders.Filter.tags(["kids"]).removing(tag: "kids") == nil)
        #expect(Reminders.Filter.today.removing(tag: "kids") == .today)
        #expect(Reminders.Filter.list(list).removing(list: list) == nil)
        #expect(Reminders.Filter.all.removing(list: list) == .all)
        #expect(Reminders.Filter.tags(["car", "kids"]) == .tags(["kids", "car"]))
    }

    @Test func `filters round-trip through their keys and colors through their hex`() {
        let id = List<Reminder>.ID(UUID())
        for filter in [Reminders.Filter.all, .completed, .flagged, .list(id), .scheduled, .tags(["a", "b, c"]), .today] {
            #expect(Reminders.Filter(key: Reminders.Filter.Key(filter)) == filter)
        }
        #expect(Reminders.Filter.Key(.tags(["b", "a"])) == Reminders.Filter.Key(.tags(["a", "b"])))
        #expect(Reminders.Filter.Key(.list(id)).rawValue == "list_\(id.rawValue.uuidString)")
        #expect(Reminders.Filter(key: Reminders.Filter.Key(rawValue: "list_not-a-uuid")) == nil)
        #expect(Color(Color.Hex(rawValue: 0x4a99ef)) == .default && Color.Hex(.default).rawValue == 0x4a99ef)
        #expect(Color.Hex(Color(red: 2, green: -1, blue: 0.5)).rawValue == 0xff0080)
    }
}
