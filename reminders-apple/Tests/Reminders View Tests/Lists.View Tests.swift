import Foundation
import FoundationEssentials_Extensions
import Reminders
import Reminders_View
import SwiftUI
import Tagged
import Testing

@Suite struct `Lists presentation` {
    @Test func `the sort menu lists the orderings as the stock app does`() {
        #expect(Lists.Ordering.allCases.map(\.title) == ["Manual", "Due Date", "Priority", "Title"])
    }

    @Test func `the day is the calendar's, not the process time zone's`() throws {
        let utc = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "UTC")!)
        let tokyo = Calendar(identifier: .gregorian, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        // 23:31 UTC on the 13th is 08:31 on the 14th in Tokyo; a reminder due 01:00 UTC on the 14th is today there, tomorrow in UTC.
        let now = Date(timeIntervalSince1970: 1_234_567_890)
        var reminder = Reminder(id: Reminder.ID(UUID()), list: Reminder.List.ID(UUID()), title: "Late")
        reminder.due = try #require(utc.date(from: DateComponents(year: 2009, month: 2, day: 14, hour: 1)))
        #expect(reminder.dueDescription(at: now, calendar: tokyo) == "Today")
        #expect(reminder.dueDescription(at: now, calendar: utc) == "Tomorrow")
    }

    @Test func `a time preset is worded as the time it sets`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 9, minute: 20)))
        let evening = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 18)))
        #expect(Reminder.TimePreset.evening.description(on: now, calendar: calendar) == evening.formatted(date: .omitted, time: .shortened))
    }

    @Test func `the due date reads as a day, a weekday, or a date, with the time only when it matters`() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 9))!
        let list = Reminder.List.ID(UUID())
        var reminder = Reminder(id: Reminder.ID(UUID()), list: list, title: "x", due: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == "Today")
        reminder.due = calendar.date(byAdding: .day, value: 1, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == "Tomorrow")
        reminder.due = calendar.date(byAdding: .day, value: 3, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(.dateTime.weekday(.wide)))
        reminder.due = calendar.date(byAdding: .day, value: 30, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(date: .abbreviated, time: .omitted))
        reminder.hasTime = true
        #expect(reminder.dueDescription(at: now, calendar: calendar)!.hasSuffix(reminder.due!.formatted(date: .omitted, time: .shortened)))
        reminder.set(due: nil)
        #expect(reminder.hasTime == false && reminder.dueDescription(at: now, calendar: calendar) == nil)
        // The week runs to six days out; the seventh is a date, and only one day back is Yesterday.
        reminder.due = calendar.date(byAdding: .day, value: 6, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(.dateTime.weekday(.wide)))
        reminder.due = calendar.date(byAdding: .day, value: 7, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(date: .abbreviated, time: .omitted))
        reminder.due = calendar.date(byAdding: .day, value: -1, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == "Yesterday")
        reminder.due = calendar.date(byAdding: .day, value: -2, to: now)
        #expect(reminder.dueDescription(at: now, calendar: calendar) == reminder.due!.formatted(date: .abbreviated, time: .omitted))
    }

    @Test func `the list color round-trips through SwiftUI`() {
        let color = Reminder.List.Color(hex: 0xed8935)
        #expect(Reminder.List.Color(color.swiftUI).hex == color.hex)
        #expect(Lists.Detail.flagged.color(list: nil) == .orange)
        #expect(Lists.Detail.list(Reminder.List.ID(UUID())).color(list: color) == color.swiftUI)
    }
}
