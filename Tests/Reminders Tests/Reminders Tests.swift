import Foundation
import Models
import Reminder
import Reminders
import Tagged
import Testing

@Suite struct `Reminders values` {
    @Test func `a tags filter is the set of its tags`() {
        #expect(Reminders.Filter.tags(["car", "kids"]) == .tags(["kids", "car"]))
    }
}

@Suite struct `Reminders call sites` {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let list = Models.List<Reminder>.ID(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    let reminder: Reminder

    init() {
        reminder = Reminder(id: Reminder.ID(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!), list: list, title: "Milk", created: now)
    }

    func reminders() -> Reminders {
        Reminders(
            create: .init { request in Reminders.Placement(request.reminder, position: request.below.map { $0.position + 1 } ?? 0) },
            read: .init(
                { _ in Reminders.Summary() },
                today: { _ in Reminders.Summary() },
                id: { _ in Reminders.Placement(reminder, position: 0) },
                page: { request in Reminders.Page(rows: [reminder], total: 1, completed: 0) },
                search: { _ in Reminders.Page() },
                preference: { request in Reminders.Preference(ordering: .dueDate, showCompleted: request.filter == .completed) }
            ),
            update: .init(
                { request in Reminders.Placement(request.reminder, position: 0) },
                order: { _ in },
                show: { _ in },
                reorder: { _ in }
            ),
            delete: .init(
                { _ in },
                completed: .init(in: { _ in }, matching: { _ in })
            ),
            lists: .init(
                create: { _ in },
                update: { _ in },
                delete: { _ in },
                reorder: { _ in }
            ),
            tags: .init(
                create: { request in Tag(request.title) },
                rename: { request in Tag(request.title) },
                delete: { _ in },
                suggest: { _ in [] }
            )
        )
    }

    @Test func `the root is the reminders resource`() throws {
        let reminders = reminders()

        let created = try reminders.create(reminder, below: nil)
        let placement = try reminders.read(reminder.id)
        let updated = try reminders.update(reminder)
        try reminders.delete(reminder.id)

        let overview = try reminders.read()
        let todayOverview = try reminders.read(today: now)
        let page = try reminders.read(page: .today, today: now, including: nil, limit: nil)
        let results = try reminders.read(search: .init(terms: ["milk"]), today: now, limit: 50)
        let preference = try reminders.read.preference(for: .completed)
        let continued = try reminders.create(reminder, below: placement)
        try reminders.update.order(.today, by: .title)
        try reminders.update.show(completed: true, in: .today)
        try reminders.update.reorder([reminder.id], in: .today)
        try reminders.delete.completed(in: .today, today: now)
        try reminders.delete.completed(matching: .init(terms: ["milk"]), dueBefore: now)

        #expect(created.position == 0 && placement.position == 0 && updated.position == 0 && continued.position == 1)
        #expect(page.rows == [reminder] && results.rows.isEmpty && overview == todayOverview)
        #expect(preference.showCompleted)
    }

    @Test func `requests are the addresses of reads`() throws {
        let reminders = reminders()
        let address = Reminders.Read.Page.Request(page: .today, today: now, including: nil, limit: nil)

        #expect(try reminders.read(address).total == 1)
        #expect(address == Reminders.Read.Page.Request(page: .today, today: now, including: nil, limit: nil))
    }

    @Test func `the sub-resources hang off the root`() throws {
        let reminders = reminders()

        try reminders.lists.create(.default(id: list))
        try reminders.lists.update(.default(id: list))
        try reminders.lists.delete(list, replacement: list)
        try reminders[keyPath: \.lists.reorder]([list])

        let tag = try reminders.tags.create("home")
        let renamed = try reminders.tags.rename("home", to: "house")
        try reminders.tags.delete("house")
        let suggestions = try reminders.tags.suggest(prefix: "ho", excluding: ["home"])

        #expect(tag == "home" && renamed == "house" && suggestions.isEmpty)
    }

    @Test func `filters round-trip through their keys`() {
        let id = Models.List<Reminder>.ID(UUID())
        for filter in [Reminders.Filter.all, .completed, .flagged, .list(id), .scheduled, .tags(["a", "b, c"]), .today] {
            #expect(Reminders.Filter(key: Reminders.Filter.Key(filter)) == filter)
        }
        #expect(Reminders.Filter.Key(.tags(["b", "a"])) == Reminders.Filter.Key(.tags(["a", "b"])))
        #expect(Reminders.Filter.Key(.list(id)).rawValue == "list_\(id.rawValue.uuidString)")
        #expect(Reminders.Filter(key: Reminders.Filter.Key(rawValue: "list_not-a-uuid")) == nil)
    }
}
