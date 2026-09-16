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
        #expect(Reminders.Filter.Preference.default(for: .completed).showCompleted)
        #expect(Reminders.Filter.Preference.Record.default(for: .all) == Reminders.Filter.Preference.Record(key: Reminders.Filter.Key(.all), ordering: .dueDate, showCompleted: false))
        #expect(Reminders.Filter.Preference.Record.default(for: .list(list)).id == Reminders.Filter.Key(.list(list)))
        #expect(Reminders.Filter.Preference(Reminders.Filter.Preference.Record.default(for: .completed)) == Reminders.Filter.Preference(showCompleted: true))
    }

    @Test func `an overview finds its lists and ranks its tags, and a detail knows its ids`() {
        let personal = List<Reminder>(id: list, title: "Personal")
        let overview = Reminders.Overview.Contents(
            lists: [List<Reminder>.Entry(List<Reminder>.Record.Entry(list: List<Reminder>.Record(personal), count: 2))],
            counts: Reminders.Overview.Counts(Reminder.Record.Counts(all: 2)),
            tags: [
                Tag<Reminder>.Entry(Tag<Reminder>.Record.Entry(tag: Tag<Reminder>.Record(Tag(title: "social")), count: 3)),
                Tag<Reminder>.Entry(tag: Tag(title: "Adulting"), count: 1),
                Tag<Reminder>.Entry(tag: Tag(title: "car"), count: 0),
            ]
        )
        #expect(overview.list(list) == personal && overview.list(List<Reminder>.ID(UUID())) == nil)
        #expect(overview.rankedTags.map(\.title) == ["social", "Adulting", "car"])
        #expect(overview.usedTags.map(\.title) == ["Adulting", "social"])
        let record = Reminder.Record(id: Reminder.ID(UUID()), listID: list, title: "Call", created: now)
        let call = Reminder(Reminder.Record.Row(reminder: record, tags: []))
        let detail = Reminders.Filter.Detail.Contents(filter: .list(list), preference: .default(for: .list(list)), rows: [call])
        #expect(detail.ids == [record.id] && detail.total == 0)
        let results = Reminders.Search.Contents(sections: [Reminders.Search.Contents.Section(list: personal, rows: [Reminder(Reminder.Record.Row(reminder: record, tags: ["a"]))])])
        #expect(results.shown == 1 && results.sections.first?.id == list)
        #expect(Reminders.Session.Record().filter == nil && Reminders.Session.Record(filter: Reminders.Filter.Key(.today), editing: record.id).editing == record.id)
    }
}
