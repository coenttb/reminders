import Foundation
import Reminders
import Testing
import Tagged

@Suite struct `Lists rules` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)

    @Test func `only incomplete reminders before today are past due`() {
        var reminder = Reminder(id: Reminder.ID(UUID()), list: Reminder.List.ID(UUID()), title: "Call", due: now.addingTimeInterval(-86_400))
        #expect(reminder.pastDue(at: now, calendar: calendar))
        reminder.status = .completed
        #expect(!reminder.pastDue(at: now, calendar: calendar))
        reminder.status = .incomplete
        reminder.due = now
        #expect(!reminder.pastDue(at: now, calendar: calendar))
    }

    @Test func `completing is a grace period before completed`() {
        var reminder = Reminder(id: Reminder.ID(UUID()), list: Reminder.List.ID(UUID()), title: "x")
        reminder.toggle()
        #expect(reminder.status == .completing && reminder.completed)
        reminder.toggle()
        #expect(reminder.status == .incomplete && !reminder.completed)
        reminder.status = .completed
        reminder.toggle()
        #expect(reminder.status == .incomplete)
    }

    @Test func `a tag detail narrows and closes as its tags go, and a list detail closes with its list`() {
        let list = Reminder.List.ID(UUID())
        #expect(Lists.Detail.tags(["car", "kids"]).removing(tag: "car") == .tags(["kids"]))
        #expect(Lists.Detail.tags(["kids"]).removing(tag: "kids") == nil)
        #expect(Lists.Detail.today.removing(tag: "kids") == .today)
        #expect(Lists.Detail.list(list).removing(list: list) == nil)
        #expect(Lists.Detail.all.removing(list: list) == .all)
    }

    @Test func `details name themselves except lists, and default to hiding completed reminders`() {
        #expect(Lists.Detail.today.title == "Today" && Lists.Detail.list(Reminder.List.ID(UUID())).title == nil)
        #expect(Lists.Detail.tags(["a"]).title == "#a" && Lists.Detail.tags(["a", "b"]).title == "2 tags")
        #expect(Lists.Detail.completed.defaultPreference == Lists.Detail.Preference(showCompleted: true))
        #expect(Lists.Detail.all.defaultPreference == Lists.Detail.Preference(ordering: .dueDate, showCompleted: false))
    }

    @Test func `a title of only whitespace is blank for reminders and lists`() {
        #expect(Reminder(id: Reminder.ID(UUID()), list: Reminder.List.ID(UUID()), title: " \n").isBlank)
        #expect(Reminder.List(id: Reminder.List.ID(UUID()), title: " \n").isBlank)
        #expect(!Reminder.List(id: Reminder.List.ID(UUID()), title: "Chores").isBlank)
    }

    @Test func `the search commits trimmed text as a token and leaves a tag prefix for the suggestions`() {
        var search = Lists.Search(text: " Take ")
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text.isEmpty)
        search.text = "#so"
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text == "#so" && search.tagPrefix == "so")
        // Typing a tag prefix alone names no reminders; with a token it does, on the tokens alone.
        #expect(!Lists.Search(text: "#so").matchesReminders)
        #expect(search.matchesReminders && search.matchedText.isEmpty)
        search.add(tag: "car")
        #expect(search.text.isEmpty && search.tags == ["car"] && search.isActive)
        #expect(!Lists.Search().isActive)
    }

    @Test func `details round-trip through their identifiers`() {
        let id = Reminder.List.ID(UUID())
        for detail in [Lists.Detail.all, .completed, .flagged, .list(id), .scheduled, .tags(["a", "b, c"]), .today] {
            #expect(Lists.Detail(id: detail.id) == detail)
        }
        #expect(Lists.Detail.tags(["b", "a"]).id == Lists.Detail.tags(["a", "b"]).id)
        #expect(Lists.Detail(id: "list_not-a-uuid") == nil)
        #expect(Reminder.List.Color(hex: 0x4a99ef).hex == 0x4a99ef)
    }

    @Test func `a day is bounded by the calendar it is asked in`() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        var tokyo = utc
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        // 2009-02-13 23:31:30 UTC is already the 14th in Tokyo.
        let day = Lists.day(containing: now, calendar: utc)
        #expect(day.lowerBound == utc.date(from: DateComponents(year: 2009, month: 2, day: 13)))
        #expect(day.upperBound == utc.date(from: DateComponents(year: 2009, month: 2, day: 14)))
        let ahead = Lists.day(containing: now, calendar: tokyo)
        #expect(ahead.lowerBound == tokyo.date(from: DateComponents(year: 2009, month: 2, day: 14)))
        #expect(ahead.contains(now) && day.contains(now))
    }

    @Test func `date and time presets resolve against now`() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 15, hour: 8, minute: 30))!
        let tomorrow = calendar.date(from: DateComponents(year: 2026, month: 9, day: 16))!
        #expect(Reminder.DatePreset.today.date(at: now, calendar: calendar) == calendar.startOfDay(for: now))
        #expect(calendar.component(.weekday, from: Reminder.DatePreset.thisWeekend.date(at: now, calendar: calendar)) == 7)
        #expect(calendar.component(.weekday, from: Reminder.DatePreset.nextWeek.date(at: now, calendar: calendar)) == 2)
        var reminder = Reminder(id: Reminder.ID(UUID()), list: Reminder.List.ID(UUID()), title: "x")
        reminder.set(timePreset: .evening, at: now, calendar: calendar)
        #expect(reminder.hasTime && calendar.component(.hour, from: reminder.due!) == 18)
        reminder.set(datePreset: .tomorrow, at: now, calendar: calendar)
        #expect(calendar.isDate(reminder.due!, inSameDayAs: tomorrow) && calendar.component(.hour, from: reminder.due!) == 18)
        reminder.set(timePreset: nil, at: now, calendar: calendar)
        #expect(!reminder.hasTime && calendar.isDate(reminder.due!, inSameDayAs: tomorrow))
        reminder.set(datePreset: nil, at: now, calendar: calendar)
        #expect(reminder.due == nil)
    }

    @Test func `a time needs a date and a date can stand alone`() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 9, minute: 20))!
        let nextHour = calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 10))!
        var reminder = Reminder(id: Reminder.ID(UUID()), list: Reminder.List.ID(UUID()), title: "x")
        reminder.set(hasTime: true, at: now, calendar: calendar)
        #expect(reminder.due == nextHour && reminder.hasTime)
        reminder.set(due: nil)
        #expect(reminder.due == nil && !reminder.hasTime)
        let day = calendar.date(from: DateComponents(year: 2026, month: 9, day: 20))!
        reminder.set(due: day)
        #expect(reminder.due == day && !reminder.hasTime)
        reminder.set(hasTime: true, at: now, calendar: calendar)
        #expect(reminder.due == calendar.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 10)) && reminder.hasTime)
    }
}
