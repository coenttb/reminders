import Foundation
import FoundationEssentials_Extensions
import Models
import Reminder
import Testing
import Tagged

@Suite struct `Reminder rules` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)
    let list = Models.List<Reminder>.ID(UUID())

    func reminder(_ title: String = "x", due: Reminder.Due? = nil) -> Reminder {
        Reminder(id: Reminder.ID(UUID()), list: list, title: title, due: due, created: now)
    }

    @Test func `only incomplete reminders before today are past due`() {
        var reminder = reminder("Call", due: .day(now.addingTimeInterval(-.day)))
        #expect(reminder.pastDue(at: now, calendar: calendar))
        reminder.completed = true
        #expect(!reminder.pastDue(at: now, calendar: calendar))
        reminder.completed = false
        reminder.due = .moment(now)
        #expect(!reminder.pastDue(at: now, calendar: calendar))
        #expect(!self.reminder().pastDue(at: now, calendar: calendar))
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
        #expect(Reminder.Due.day(date).isPast(at: date.addingTimeInterval(.day), calendar: calendar))
        #expect(!Reminder.Due.moment(date).isPast(at: date.addingTimeInterval(3_600), calendar: calendar))
    }

    @Test func `a repeat is a Foundation recurrence rule or nothing`() {
        var reminder = reminder()
        #expect(reminder.repeats == nil)
        reminder.repeats = Calendar.RecurrenceRule(calendar: calendar, frequency: .weekly)
        #expect(reminder.repeats?.frequency == .weekly && reminder.repeats?.interval == 1)
    }
}
