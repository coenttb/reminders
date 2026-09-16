import Foundation
import FoundationEssentials_Extensions
import Organizing
import Reminders
import Testing
import Tagged

@Suite struct `Reminder rules` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)
    let list = List<Reminder>.ID(UUID())

    func reminder(_ title: String = "x", due: Reminder.Due? = nil) -> Reminder {
        Reminder(id: Reminder.ID(UUID()), list: list, title: title, due: due)
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

    @Test func `a completion toggles between incomplete and completed`() {
        var reminder = reminder()
        reminder.toggle()
        #expect(reminder.completion == .completed && reminder.completed)
        reminder.toggle()
        #expect(reminder.completion == .incomplete && !reminder.completed)
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

    @Test func `a filter narrows and closes as its tags and list go`() {
        #expect(Reminder.Filter.tags(["car", "kids"]).removing(tag: "car") == .tags(["kids"]))
        #expect(Reminder.Filter.tags(["kids"]).removing(tag: "kids") == nil)
        #expect(Reminder.Filter.today.removing(tag: "kids") == .today)
        #expect(Reminder.Filter.list(list).removing(list: list) == nil)
        #expect(Reminder.Filter.all.removing(list: list) == .all)
        #expect(Reminder.Filter.list(list).isList && !Reminder.Filter.all.isList)
    }

    @Test func `a filter contains the reminders it shows`() throws {
        let today = try #require(calendar.day(containing: now))
        var reminder = reminder("Call", due: .moment(now))
        reminder.tags = ["car"]
        reminder.flagged = true
        for filter in [Reminder.Filter.all, .flagged, .scheduled, .today, .list(list), .tags(["car", "kids"])] {
            #expect(filter.contains(reminder, today: today))
        }
        #expect(!Reminder.Filter.completed.contains(reminder, today: today))
        #expect(!Reminder.Filter.list(List<Reminder>.ID(UUID())).contains(reminder, today: today))
        #expect(!Reminder.Filter.tags(["kids"]).contains(reminder, today: today))
        reminder.due = .day(today.upperBound)
        #expect(!Reminder.Filter.today.contains(reminder, today: today) && Reminder.Filter.scheduled.contains(reminder, today: today))
        reminder.completion = .completed
        #expect(Reminder.Filter.completed.contains(reminder, today: today) && Reminder.Filter.flagged.contains(reminder, today: today))
        #expect(!Reminder.Filter.scheduled.contains(reminder, today: today) && !Reminder.Filter.today.contains(reminder, today: today))
    }

    @Test func `orderings sort by date, priority, or title, and by position among equals`() {
        var a = reminder("banana"), b = reminder("Apple"), c = reminder("cherry")
        (a.position, b.position, c.position) = (0, 1, 2)
        b.due = .day(now)
        c.due = .day(now.addingTimeInterval(.day))
        c.priority = .high
        b.priority = .high
        b.flagged = true
        a.priority = .low
        func sorted(_ ordering: Reminder.Ordering) -> [String] {
            [a, b, c].sorted { ordering.areInIncreasingOrder($0, $1) }.map(\.title)
        }
        #expect(sorted(.manual) == ["banana", "Apple", "cherry"])
        #expect(sorted(.dueDate) == ["Apple", "cherry", "banana"])
        #expect(sorted(.priority) == ["Apple", "cherry", "banana"])
        #expect(sorted(.title) == ["Apple", "banana", "cherry"])
        (a.created, b.created, c.created) = (now, now.addingTimeInterval(-.day), now)
        #expect(sorted(.creationDate) == ["Apple", "banana", "cherry"])
        var d = a
        d.title = "Banana"
        d.position = -1
        #expect([a, d].sorted { Reminder.Ordering.areInIncreasingOrder($0, $1, for: .title) }.map(\.position) == [-1, 0])
    }
}
