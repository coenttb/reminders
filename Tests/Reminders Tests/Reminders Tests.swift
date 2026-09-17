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
            create: { request in Reminders.Placement(request.reminder, position: request.below.map { $0.position + 1 } ?? 0) },
            retrieve: { id in Reminders.Placement(reminder, position: 0) },
            update: { reminder in Reminders.Placement(reminder, position: 0) },
            delete: { id in },
            list: { request in .init(selection: request.selection, preference: .default(for: .all)) },
            reorder: { request in },
            complete: { id in },
            reopen: { id in },
            deleteCompleted: { request in },
            overview: { request in .init() },
            lists: .init(
                create: { list in },
                update: { list in },
                delete: { id, replacement in },
                reorder: { ids in }
            ),
            tags: .init(
                create: { title in Tag(title) },
                update: { request in Tag(request.title) },
                delete: { tag in },
                list: { request in [] }
            ),
            preferences: .init(
                update: { request in }
            )
        )
    }

    @Test func `the root is the reminders resource`() throws {
        let reminders = reminders()

        let created = try reminders.create(.init(reminder))
        let placement = try reminders.retrieve(reminder.id)
        let updated = try reminders.update(reminder)
        try reminders.delete(reminder.id)

        let page = try reminders.list(.init(selection: .filter(.today), today: today))
        let page2 = try reminders.list(.init(selection: .search(.init(terms: ["milk"])), today: today, including: nil, limit: 50))
        let continued = try reminders.create(.init(reminder, below: placement))
        try reminders.reorder(.init(ids: [reminder.id], in: .today))
        try reminders.complete(reminder.id)
        try reminders.reopen(reminder.id)
        try reminders.deleteCompleted(.filter(.today, today: today))
        try reminders.deleteCompleted(.search(.init(terms: ["milk"]), dueBefore: now))

        let overview = try reminders.overview(.init(today: today))

        #expect(created.position == 0 && placement.position == 0 && updated.position == 0 && continued.position == 1)
        #expect(page.selection == .filter(.today) && page2.rows.isEmpty && overview.counts == .init())
    }

    @Test func `the sub-resources hang off the root`() throws {
        let reminders = reminders()

        try reminders.lists.create(.default(id: list))
        try reminders.lists.update(.default(id: list))
        try reminders.lists.delete(list, replacement: list)
        try reminders[keyPath: \.lists.reorder]([list])
        try reminders.lists.reorder([list])

        let tag = try reminders.tags.create("home")
        let renamed = try reminders.tags.update(.init(tag: "home", title: "house"))
        try reminders.tags.delete("house")
        let suggestions = try reminders.tags.list(.init(prefix: "ho", excluding: ["home"]))

        try reminders.preferences.update(.init(filter: .today, change: .ordering(.title)))
        try reminders.preferences.update(.init(filter: .today, change: .toggleShowCompleted))

        #expect(tag == "home" && renamed == "house" && suggestions.isEmpty)
    }
}
