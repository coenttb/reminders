import Foundation
import FoundationEssentials_Extensions
import Organizing
import Reminders
import Reminders_Interface
import Reminders_View
import SwiftUI
import Tagged
import Testing

@Suite struct `Reminder presentation` {
    let list = List<Reminder>.ID(UUID())

    @Test func `the sort menu and the chips name the domain's values as the stock app does`() {
        #expect(Reminders.Ordering.allCases.map(\.title) == ["Manual", "Deadline", "Creation Date", "Priority", "Title"])
        #expect(Reminder.Priority.allCases.map(\.title) == ["Low", "Medium", "High"])
        #expect(Reminder.Priority.allCases.map(\.marks) == ["!", "!!", "!!!"])
        #expect(Reminder.Repeat.allCases.map(\.title) == ["Never", "Daily", "Weekly", "Monthly", "Yearly"])
        #expect(Reminder.Location.allCases.map(\.title) == ["Getting in Car", "Getting out of Car"])
        #expect(Reminders.Reminder.Due.Preset.allCases.map(\.title) == ["Today", "Tomorrow", "This Weekend", "Next Week"])
        #expect(Reminders.Reminder.Due.Preset.Time.allCases.map(\.title) == ["Morning", "Midday", "Afternoon", "Evening", "Night"])
    }

    @Test func `filters name themselves except lists, and tags show as hashtags`() {
        #expect(Reminders.Filter.today.title == "Today" && Reminders.Filter.list(list).title == nil)
        #expect(Reminders.Filter.tags(["a"]).title == "#a" && Reminders.Filter.tags(["a", "b"]).title == "2 tags")
        let reminder = Reminder(id: Reminder.ID(UUID()), list: list, tags: ["kids", "car"], created: .distantPast)
        #expect(Tag<Reminder>(title: "kids").hashtag == "#kids" && reminder.tagLine == "#car #kids")
        #expect(Reminder(id: reminder.id, list: list, created: .distantPast).tagLine.isEmpty)
    }

    @Test func `the day is the calendar's, not the process time zone's`() throws {
        let utc = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "UTC")!)
        let tokyo = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        let now = Date(timeIntervalSince1970: 1_234_567_890)
        let due = Reminder.Due.day(try #require(utc.date(from: DateComponents(year: 2009, month: 2, day: 14, hour: 1))))
        #expect(due.description(at: now, calendar: tokyo) == "Today")
        #expect(due.description(at: now, calendar: utc) == "Tomorrow")
    }

    @Test func `a time preset is worded as the time it sets, by the given calendar`() throws {
        let calendar = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "UTC")!)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 9, minute: 20)))
        let evening = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 18)))
        let style = Date.FormatStyle(date: .omitted, time: .shortened, calendar: calendar, timeZone: calendar.timeZone)
        #expect(Reminders.Reminder.Due.Preset.Time.evening.description(on: now, calendar: calendar) == evening.formatted(style))
        #expect(Reminder.Due.moment(evening).timeDescription(calendar: calendar) == evening.formatted(style))
        #expect(Reminder.Due.day(evening).timeDescription(calendar: calendar) == nil)
    }

    @Test func `the due date reads as a day, a weekday, or a date, with the time only when it matters`() throws {
        let calendar = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "UTC")!)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 9)))
        let style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone)
        func due(_ days: Int) throws -> Date { try #require(calendar.date(byAdding: .day, value: days, to: now)) }
        func worded(_ due: Reminder.Due) -> String { due.description(at: now, calendar: calendar) }
        let short = Date.FormatStyle(date: .abbreviated, time: .omitted, calendar: calendar, timeZone: calendar.timeZone)
        let time = Date.FormatStyle(date: .omitted, time: .shortened, calendar: calendar, timeZone: calendar.timeZone)
        let in1 = try due(1), in3 = try due(3), in6 = try due(6), in7 = try due(7), in30 = try due(30), ago1 = try due(-1), ago2 = try due(-2)
        #expect(worded(.day(now)) == "Today")
        #expect(worded(.day(in1)) == "Tomorrow")
        #expect(worded(.day(in3)) == in3.formatted(style.weekday(.wide)))
        #expect(worded(.day(in30)) == in30.formatted(short))
        #expect(worded(.moment(in30)).hasSuffix(in30.formatted(time)))
        #expect(worded(.day(in6)) == in6.formatted(style.weekday(.wide)))
        #expect(worded(.day(in7)) == in7.formatted(short))
        #expect(worded(.day(ago1)) == "Yesterday")
        #expect(worded(.day(ago2)) == ago2.formatted(short))
        let tokyo = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        #expect(Reminder.Due.day(ago1).description(at: now, calendar: tokyo) == "Yesterday")
    }

    @Test func `the list color round-trips through SwiftUI`() {
        let color = Organizing.Color(red: 237 / 255, green: 137 / 255, blue: 53 / 255)
        let round = Organizing.Color(SwiftUI.Color(color))
        #expect(abs(round.red - color.red) < 0.002 && abs(round.green - color.green) < 0.002 && abs(round.blue - color.blue) < 0.002)
        #expect(Reminders.Filter.flagged.color(list: nil) == .orange)
        #expect(Reminders.Filter.list(list).color(list: color) == SwiftUI.Color(color))
        #expect(Organizing.List<Reminder>.Form.SwiftUI.palette.map(\.name) == ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Brown"])
    }
}
