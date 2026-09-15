import Foundation
import Reminders
import Reminders_View
import SwiftUI
import Tagged
import Testing

@Suite struct `Lists presentation` {
    @Test func `the sort menu lists the orderings as the stock app does`() {
        #expect(Lists.Ordering.allCases.map(\.title) == ["Manual", "Due Date", "Priority", "Title"])
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
