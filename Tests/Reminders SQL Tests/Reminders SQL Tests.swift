import Foundation
import Models
import Reminder
import Reminders
import Reminders_SQL
import Testing
import Tagged

@Suite struct `Reminders SQL records` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let list = Models.List<Reminder>.ID(UUID())

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
        #expect(Reminders.Summary.Counts(Reminder.Record.Counts(all: 3, flagged: 1)).all == 3)
    }

    @Test func `an overview finds its lists and ranks its tags, and a detail knows its ids`() {
        let personal = Models.List<Reminder>(id: list, title: "Personal")
        let overview = Reminders.Summary(
            lists: [Models.List<Reminder>.Entry(Models.List<Reminder>.Record.Entry(list: Models.List<Reminder>.Record(personal), count: 2))],
            counts: Reminders.Summary.Counts(Reminder.Record.Counts(all: 2)),
            tags: [
                Tag<Reminder>.Entry(Tag<Reminder>.Record.Entry(tag: Tag<Reminder>.Record(Tag("social")), count: 3)),
                Tag<Reminder>.Entry(tag: Tag("Adulting"), count: 1),
                Tag<Reminder>.Entry(tag: Tag("car"), count: 0),
            ]
        )
        #expect(overview.lists.map(\.list) == [personal] && overview.tags.map(\.tag.rawValue) == ["social", "Adulting", "car"])
        let record = Reminder.Record(id: Reminder.ID(UUID()), listID: list, title: "Call", created: now)
        let call = Reminder(Reminder.Record.Row(reminder: record, tags: []))
        let page = Reminders.Page(rows: [call])
        #expect(page.rows.map(\.id) == [record.id] && page.total == 0)
        let stored = Reminders.Preference.Record(Reminders.Preference(ordering: .title, direction: .reverse, showCompleted: true), for: .today)
        #expect(stored.key == Reminders.Filter.Key(.today) && Reminders.Preference(stored) == Reminders.Preference(ordering: .title, direction: .reverse, showCompleted: true))
        #expect(Reminders.Preference.Record(key: Reminders.Filter.Key(.today)).direction == .forward)
    }
}
