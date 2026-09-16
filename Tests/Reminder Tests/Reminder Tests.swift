import Foundation
import FoundationEssentials_Extensions
import Models
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
        reminder.set(due: nil)
        #expect(reminder.due == nil)
    }
}
