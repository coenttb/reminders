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
        for detail in [Lists.Detail.all, .completed, .flagged, .list(id), .scheduled, .tags(["a", "b"]), .today] {
            #expect(Lists.Detail(id: detail.id) == detail)
        }
        #expect(Reminder.List.Color(hex: 0x4a99ef).hex == 0x4a99ef)
    }
}
