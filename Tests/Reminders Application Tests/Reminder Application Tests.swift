import Foundation
import FoundationEssentials_Extensions
import Organizing
import Reminders
import Reminders_Application
import Testing
import Tagged

@Suite struct `Reminder application rules` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)
    let list = List<Reminder>.ID(UUID())

    func reminder(_ title: String = "x") -> Reminder {
        Reminder(id: Reminder.ID(UUID()), list: list, title: title)
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

    @Test func `pending is the grace period between the tap and completed`() {
        let (a, b) = (Reminder.ID(UUID()), Reminder.ID(UUID()))
        var pending = Reminder.Completion.Pending()
        #expect(pending.isEmpty && Reminder.Completion.Pending.grace == .seconds(5))
        pending.toggle(a)
        pending.toggle(b)
        #expect(pending == [a, b] && pending.contains(a))
        pending.toggle(a)
        #expect(pending == [b])
        pending.elapse()
        #expect(pending.isEmpty && Reminder.Completion.Pending.toggling(pending, a) == [a])
    }

    @Test func `filters default to hiding completed reminders except Completed`() {
        #expect(Reminder.Filter.completed.defaultPreference == Reminder.Filter.Preference(showCompleted: true))
        #expect(Reminder.Filter.all.defaultPreference == Reminder.Filter.Preference(ordering: .dueDate, showCompleted: false))
        #expect(Reminder.Filter.Preference.default(for: .list(list)) == Reminder.Filter.Preference())
    }

    @Test func `the search commits trimmed text as a token and leaves a tag prefix for the suggestions`() {
        var search = Reminder.Search(text: " Take ")
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text.isEmpty)
        search.text = "#so"
        search.commitText()
        #expect(search.tokens == [.near("Take")] && search.text == "#so" && search.tagPrefix == "so")
        #expect(!Reminder.Search(text: "#so").matchesReminders)
        #expect(search.matchesReminders && search.matchedText.isEmpty)
        search.add(tag: "car")
        #expect(search.text.isEmpty && search.tags == ["car"] && search.isActive)
        #expect(!Reminder.Search().isActive)
        #expect(Reminder.Search.Results(sections: [Reminder.Search.Results.Section(list: List(id: list), reminders: [reminder()])]).reminders.count == 1)
    }

    @Test func `an editing session starts saved and knows when the draft differs`() {
        let stored = reminder("Call")
        var editing = Reminder.Editing(stored, session: UUID())
        #expect(editing.isSaved && editing.id == stored.id && editing.place == stored)
        editing.draft.title = "Call back"
        #expect(!editing.isSaved && editing.saved == stored)
    }

    @Test func `an overview finds its lists and a detail its reminders`() {
        let personal = List<Reminder>(id: list, title: "Personal")
        let overview = Reminder.Overview(lists: [List<Reminder>.Entry(list: personal, count: 2)], counts: Reminder.Filter.Counts(all: 2))
        #expect(overview.list(list) == personal && overview.list(List<Reminder>.ID(UUID())) == nil)
        let row = Reminder.Filter.Detail.Row(reminder: reminder(), color: .default)
        let detail = Reminder.Filter.Detail(filter: .list(list), color: personal.color, preference: Reminder.Filter.Preference(), rows: [row])
        #expect(detail.reminders == [row.reminder] && row.id == row.reminder.id)
        #expect(Reminder.Session().filter == nil && Reminder.Session(filter: .today, editing: row.id).editing == row.id)
    }

    @Test func `a window starts at one step, widens while there is more, and starts over for another key`() {
        var window = Reminder.Window<Reminder.Filter>()
        let step = Reminder.Window<Reminder.Filter>.step
        #expect(window.limit(for: .all) == step && window.limit(for: .today) == step)
        window.widen(for: .all, shown: step, total: step)
        #expect(window.limit(for: .all) == step)
        window.widen(for: .all, shown: step, total: step + 1)
        #expect(window.limit(for: .all) == 2 * step && window.limit(for: .today) == step)
        window.extend(for: .all, by: 1)
        #expect(window.limit(for: .all) == 2 * step + 1)
        window.open(for: .today)
        #expect(window.limit(for: .today) == nil && window.limit(for: .all) == step)
        window.widen(for: .today, shown: 10, total: 20)
        window.extend(for: .today, by: 1)
        #expect(window.limit(for: .today) == nil)
        let margin = Reminder.Window<Reminder.Filter>.margin
        #expect(Reminder.Window<Reminder.Filter>.nearsEnd(step - margin, of: step, total: step + 1))
        #expect(!Reminder.Window<Reminder.Filter>.nearsEnd(step - margin - 1, of: step, total: step + 1))
        #expect(!Reminder.Window<Reminder.Filter>.nearsEnd(step - 1, of: step, total: step))
    }
}
