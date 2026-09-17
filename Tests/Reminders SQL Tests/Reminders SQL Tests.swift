import Foundation
import Models
import Reminder
import Reminders
import Reminders_SQL
import Testing
import Tagged

@Suite struct `Reminders SQL records` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let list = List<Reminder>.ID(UUID())

    @Test func `a reminder round-trips through its record and row`() {
        let reminder = Reminder(
            id: Reminder.ID(UUID()),
            list: list,
            title: "Groceries",
            notes: "Milk",
            due: .moment(now),
            repeats: Calendar.RecurrenceRule(calendar: Calendar(identifier: .gregorian), frequency: .weekly),
            priority: .high,
            flagged: true,
            completed: true,
            tags: ["kids", "car"],
            created: now.addingTimeInterval(-86_400)
        )
        let draft = Reminder.Record.Draft(reminder, position: 4)
        #expect(draft.id == reminder.id && draft.dueDate == now && draft.hasTime && draft.completed)
        let record = Reminder.Record(
            id: reminder.id,
            listID: reminder.list,
            title: reminder.title,
            notes: reminder.notes,
            dueDate: now,
            hasTime: true,
            flagged: true,
            priority: .high,
            completed: true,
            position: 4,
            repeats: reminder.repeats,
            created: reminder.created
        )
        #expect(Reminder.Record.Draft(record) == draft)
        #expect(Reminder(Reminder.Record.Row(reminder: record, tags: ["car", "kids"])) == reminder)
        #expect(Reminders.Overview.Counts(Reminder.Record.Counts(all: 3, flagged: 1))[.all] == 3 && Reminders.Overview.Counts()[.completed] == nil)
    }

    @Test func `filters default to hiding completed reminders except Completed`() {
        #expect(Reminders.Preference.Record.default(for: .all) == Reminders.Preference.Record(key: Reminders.Filter.Key(.all), ordering: .dueDate, showCompleted: false))
        #expect(Reminders.Preference.Record.default(for: .list(list)).id == Reminders.Filter.Key(.list(list)))
        #expect(Reminders.Preference(Reminders.Preference.Record.default(for: .completed)) == Reminders.Preference(showCompleted: true))
    }

    @Test func `an overview finds its lists and ranks its tags, and a detail knows its ids`() {
        let personal = List<Reminder>(id: list, title: "Personal")
        let overview = Reminders.Overview.Fetch.Result(
            lists: [List<Reminder>.Entry(List<Reminder>.Record.Entry(list: List<Reminder>.Record(personal), count: 2))],
            counts: Reminders.Overview.Counts(Reminder.Record.Counts(all: 2)),
            tags: [
                Tag<Reminder>.Entry(Tag<Reminder>.Record.Entry(tag: Tag<Reminder>.Record(Tag("social")), count: 3)),
                Tag<Reminder>.Entry(tag: Tag("Adulting"), count: 1),
                Tag<Reminder>.Entry(tag: Tag("car"), count: 0),
            ]
        )
        #expect(overview.lists.map(\.list) == [personal] && overview.tags.map(\.tag.rawValue) == ["social", "Adulting", "car"])
        let record = Reminder.Record(id: Reminder.ID(UUID()), listID: list, title: "Call", created: now)
        let call = Reminder(Reminder.Record.Row(reminder: record, tags: []))
        let page = Reminders.Listing.Fetch.Result(selection: .filter(.list(list)), preference: .default(for: .list(list)), rows: [call])
        #expect(page.rows.map(\.id) == [record.id] && page.total == 0)
        let stored = Reminders.Preference.Record(Reminders.Preference(ordering: .title, showCompleted: true), for: .today)
        #expect(stored.key == Reminders.Filter.Key(.today) && Reminders.Preference(stored) == Reminders.Preference(ordering: .title, showCompleted: true))
    }

    @Test func `filters round-trip through their keys`() {
        let id = List<Reminder>.ID(UUID())
        for filter in [Reminders.Filter.all, .completed, .flagged, .list(id), .scheduled, .tags(["a", "b, c"]), .today] {
            #expect(Reminders.Filter(key: Reminders.Filter.Key(filter)) == filter)
        }
        #expect(Reminders.Filter.Key(.tags(["b", "a"])) == Reminders.Filter.Key(.tags(["a", "b"])))
        #expect(Reminders.Filter.Key(.list(id)).rawValue == "list_\(id.rawValue.uuidString)")
        #expect(Reminders.Filter(key: Reminders.Filter.Key(rawValue: "list_not-a-uuid")) == nil)
    }
}
