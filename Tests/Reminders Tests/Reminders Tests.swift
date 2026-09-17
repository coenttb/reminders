import Foundation
import Models
import Reminder
import Reminders
import Testing
import Tagged

@Suite struct `Reminders values` {
    @Test func `a tags filter is the set of its tags`() {
        #expect(Reminders.Filter.tags(["car", "kids"]) == .tags(["kids", "car"]))
    }

    @Test func `the Completed smart list is the only one that shows completed reminders by default`() {
        #expect(Reminders.Preference.default(for: .completed) == Reminders.Preference(ordering: .dueDate, showCompleted: true))
        #expect(Reminders.Preference.default(for: .today) == Reminders.Preference())
    }
}

@Suite struct `Reminders call sites` {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let list = Models.List<Reminder>.ID(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    let reminder: Reminder

    init() {
        reminder = Reminder(id: Reminder.ID(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!), list: list, title: "Milk", created: now)
    }

    var today: Range<Date> { now..<now.addingTimeInterval(86_400) }

    func reminders() -> Reminders {
        Reminders(
            create: .init(client: .init { request in Reminders.Placement(request.reminder, position: request.below.map { $0.position + 1 } ?? 0) }),
            retrieve: .init(client: .init { id in Reminders.Placement(reminder, position: 0) }),
            update: .init(client: .init { reminder in Reminders.Placement(reminder, position: 0) }),
            delete: .init(client: .init { id in }),
            list: .init(client: .init { request in .init(selection: request.selection, preference: .default(for: .all)) }),
            reorder: .init(client: .init { request in }),
            complete: .init(client: .init { id in }),
            reopen: .init(client: .init { id in }),
            deleteCompleted: .init(client: .init { request in }),
            overview: .init(client: .init { request in .init() }),
            lists: .init(
                create: .init(client: .init { list in }),
                update: .init(client: .init { list in }),
                delete: .init(client: .init { request in }),
                reorder: .init(client: .init { ids in })
            ),
            tags: .init(
                create: .init(client: .init { title in Tag(title) }),
                update: .init(client: .init { request in Tag(request.title) }),
                delete: .init(client: .init { tag in }),
                list: .init(client: .init { request in [] })
            ),
            preferences: .init(
                update: .init(client: .init { request in })
            )
        )
    }

    @Test func `the root is the reminders resource`() throws {
        let reminders = reminders()

        let created = try reminders.create.client(.init(reminder))
        let placement = try reminders.retrieve.client(reminder.id)
        let updated = try reminders.update.client(reminder)
        try reminders.delete.client(reminder.id)

        let page = try reminders.list.client(.init(selection: .filter(.today), today: today))
        let page2 = try reminders.list.client(.init(selection: .search(.init(terms: ["milk"])), today: today, including: nil, limit: 50))
        let continued = try reminders.create.client(.init(reminder, below: placement))
        try reminders.reorder.client(.init(ids: [reminder.id], in: .today))
        try reminders.complete.client(reminder.id)
        try reminders.reopen.client(reminder.id)
        try reminders.deleteCompleted.client(.filter(.today, today: today))
        try reminders.deleteCompleted.client(.search(.init(terms: ["milk"]), dueBefore: now))

        let overview = try reminders.overview.client(.init(today: today))

        #expect(created.position == 0 && placement.position == 0 && updated.position == 0 && continued.position == 1)
        #expect(page.selection == .filter(.today) && page2.rows.isEmpty && overview.counts == .init())
    }

    @Test func `the sub-resources hang off the root`() throws {
        let reminders = reminders()

        try reminders.lists.create.client(.default(id: list))
        try reminders.lists.update.client(.default(id: list))
        try reminders.lists.delete.client(.init(id: list, replacement: list))
        try reminders.lists.reorder.client([list])

        let tag = try reminders.tags.create.client("home")
        let renamed = try reminders.tags.update.client(.init(tag: "home", title: "house"))
        try reminders.tags.delete.client("house")
        let suggestions = try reminders.tags.list.client(.init(prefix: "ho", excluding: ["home"]))

        try reminders.preferences.update.client(.init(filter: .today, change: .ordering(.title)))
        try reminders.preferences.update.client(.init(filter: .today, change: .toggleShowCompleted))

        #expect(tag == "home" && renamed == "house" && suggestions.isEmpty)
    }
}
