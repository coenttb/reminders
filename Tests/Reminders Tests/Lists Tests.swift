import Foundation
import Reminders
import Testing
import Tagged

@Suite struct `Lists rules` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)

    @Test func `the home counts open reminders only`() {
        let lists = Lists.sample(at: now)
        #expect(lists.stats(at: now) == Lists.Stats(all: 8, flagged: 2, scheduled: 7, today: 2))
        #expect(lists.count(in: lists.orderedLists[0].id) == 4)
        #expect(lists.usedTags.map(\.title) == ["adulting", "car", "kids", "night", "optional", "social", "someday"])
    }

    @Test func `a detail filters by membership and orders by its preference`() {
        var lists = Lists.sample(at: now)
        let personal = Lists.Detail.list(lists.orderedLists[0].id)
        #expect(lists.reminders(in: personal, at: now).map(\.title) == ["Haircut", "Doctor appointment", "Buy concert tickets", "Groceries"])
        lists.set(ordering: .priority, for: personal)
        #expect(lists.reminders(in: personal, at: now).map(\.title) == ["Doctor appointment", "Haircut", "Groceries", "Buy concert tickets"])
        lists.set(ordering: .title, for: personal)
        #expect(lists.reminders(in: personal, at: now).map(\.title) == ["Buy concert tickets", "Doctor appointment", "Groceries", "Haircut"])
        lists.toggleShowCompleted(for: personal)
        #expect(lists.reminders(in: personal, at: now).map(\.title).last == "Take a walk")
        #expect(lists.reminders(in: .completed, at: now).count == 3)
        #expect(lists.reminders(in: .today, at: now).count == 2)
        #expect(lists.reminders(in: .tags(["social"]), at: now).map(\.title) == ["Buy concert tickets", "Prepare for WWDC"])
    }

    @Test func `completing is a grace period before completed`() {
        var lists = Lists.sample(at: now)
        let groceries = lists.reminders[0].id
        lists.toggle(groceries)
        #expect(lists.completing == [groceries])
        #expect(lists.stats(at: now).all == 7)
        let personal = Lists.Detail.list(lists.reminders[0].list)
        #expect(lists.reminders(in: personal, at: now).map(\.id).contains(groceries))
        #expect(lists.reminders(in: personal, at: now).last?.id == groceries)
        lists.toggle(groceries)
        #expect(lists.completing.isEmpty)
        lists.toggle(groceries)
        lists.completeCompleting()
        #expect(lists.reminder(groceries)?.status == .completed)
    }

    @Test func `deleting a list takes its reminders and closes its detail`() {
        var lists = Lists.sample(at: now)
        let family = lists.orderedLists[1].id
        lists.detail = .list(family)
        lists.delete(list: family)
        #expect(lists.lists.count == 2)
        #expect(lists.reminders.count == 8)
        #expect(lists.detail == nil)
    }

    @Test func `tags are shared, renamed everywhere, and deleted everywhere`() {
        var lists = Lists.sample(at: now)
        lists.rename(tag: "social", to: "friends")
        #expect(lists.reminders.filter { $0.tags.contains("friends") }.count == 3)
        lists.delete(tag: "friends")
        #expect(lists.reminders.allSatisfy { !$0.tags.contains("friends") })
        lists.add(tag: "Someday")
        #expect(lists.tags.count == 6)
    }

    @Test func `moving reminders switches the detail to manual ordering`() {
        var lists = Lists.sample(at: now)
        let personal = Lists.Detail.list(lists.orderedLists[0].id)
        lists.move(reminders: [3], to: 0, in: personal, at: now)
        #expect(lists.preference(for: personal).ordering == .manual)
        #expect(lists.reminders(in: personal, at: now).map(\.title).first == "Groceries")
        lists.move(lists: [2], to: 0)
        #expect(lists.orderedLists.map(\.title) == ["Business", "Personal", "Family"])
    }

    @Test func `search matches text and tag tokens and can clear completed matches`() {
        var lists = Lists.sample(at: now)
        var search = Lists.Search(text: "Take")
        #expect(lists.matches(search).map(\.title) == ["Take out trash", "Take a walk"])
        search.add(tag: "car")
        #expect(search.text.isEmpty)
        search.text = "Take"
        #expect(lists.matches(search).map(\.title) == ["Take a walk"])
        #expect(lists.tagSuggestions(for: Lists.Search(text: "#so")).map(\.title) == ["social", "someday"])
        lists.deleteCompleted(matching: Lists.Search(text: "Take"), olderThanMonths: 12, at: now)
        #expect(lists.reminders.count == 11)
        lists.deleteCompleted(matching: Lists.Search(text: "Take"), olderThanMonths: 1, at: now)
        #expect(lists.reminders.count == 10)
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

    @Test func `inline editing starts a row, chains on return, and drops blank rows`() {
        var lists = Lists.sample(at: now)
        let personal = lists.orderedLists[0].id
        let first = Reminder.ID(UUID())
        lists.startNewReminder(in: personal, id: first)
        #expect(lists.editing == first && lists.reminder(first)?.list == personal)
        lists.continueEditing(id: Reminder.ID(UUID()))
        #expect(lists.editing == nil && lists.reminder(first) == nil)
        lists.startNewReminder(in: personal, id: first)
        lists.upsert({ var r = lists.reminder(first)!; r.title = "Milk"; return r }())
        let second = Reminder.ID(UUID())
        lists.continueEditing(id: second)
        #expect(lists.editing == second && lists.reminder(first)?.title == "Milk")
        #expect(lists.reminder(second)?.position == lists.reminder(first)!.position + 1)
        // The new row sits beneath its anchor under due-date ordering, and the anchor keeps its
        // place while a date is set on it, until editing ends.
        lists.set(ordering: .dueDate, for: .list(personal))
        var shown = lists.reminders(in: .list(personal), at: now).map(\.id)
        #expect(shown.firstIndex(of: second) == shown.firstIndex(of: first).map { $0 + 1 })
        lists.edit(first)
        let before = lists.reminders(in: .list(personal), at: now).map(\.id).firstIndex(of: first)
        lists.upsert({ var r = lists.reminder(first)!; r.due = now.addingTimeInterval(-400_000); return r }())
        shown = lists.reminders(in: .list(personal), at: now).map(\.id)
        #expect(shown.firstIndex(of: first) == before)
        lists.endEditing()
        #expect(lists.reminders(in: .list(personal), at: now).first?.id == first)
        lists.edit(first)
        #expect(lists.editing == first && lists.reminder(second) == nil)
        lists.endEditing()
        #expect(lists.editing == nil && lists.reminder(first) != nil)
        lists.delete(reminder: first)
        lists.edit(first)
        #expect(lists.editing == nil)
    }

    @Test func `date and time presets resolve against now`() {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 15, hour: 8, minute: 30))!
        #expect(Reminder.DatePreset.today.date(at: now) == calendar.startOfDay(for: now))
        #expect(calendar.component(.weekday, from: Reminder.DatePreset.thisWeekend.date(at: now)) == 7)
        #expect(calendar.component(.weekday, from: Reminder.DatePreset.nextWeek.date(at: now)) == 2)
        var reminder = Reminder(id: Reminder.ID(UUID()), list: Reminder.List.ID(UUID()), title: "x")
        reminder.set(timePreset: .evening, at: now)
        #expect(reminder.hasTime && calendar.component(.hour, from: reminder.due!) == 18)
        reminder.set(datePreset: .tomorrow, at: now)
        #expect(calendar.isDateInTomorrow(reminder.due!) && calendar.component(.hour, from: reminder.due!) == 18)
        reminder.set(timePreset: nil, at: now)
        #expect(!reminder.hasTime && calendar.isDateInTomorrow(reminder.due!))
        reminder.set(datePreset: nil, at: now)
        #expect(reminder.due == nil)
    }

    @Test func `a time needs a date and a date can stand alone`() {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 9, minute: 20))!
        let nextHour = calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 10))!
        var reminder = Reminder(id: Reminder.ID(UUID()), list: Reminder.List.ID(UUID()), title: "x")
        reminder.set(hasTime: true, at: now)
        #expect(reminder.due == nextHour && reminder.hasTime)
        reminder.set(due: nil)
        #expect(reminder.due == nil && !reminder.hasTime)
        let day = calendar.date(from: DateComponents(year: 2026, month: 9, day: 20))!
        reminder.set(due: day)
        #expect(reminder.due == day && !reminder.hasTime)
        reminder.set(hasTime: true, at: now)
        #expect(reminder.due == calendar.date(from: DateComponents(year: 2026, month: 9, day: 20, hour: 10)) && reminder.hasTime)
    }
}
