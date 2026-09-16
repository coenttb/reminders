import Foundation
import Organizing
import Reminders
import Reminders_Interface
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
            flagged: true,
            priority: .high,
            completion: .completed,
            tags: ["kids", "car"],
            position: 4,
            location: .gettingInCar,
            repeats: .weekly,
            created: now.addingTimeInterval(-86_400)
        )
        let draft = Reminder.Record.Draft(reminder)
        #expect(draft.id == reminder.id && draft.dueDate == now && draft.hasTime && draft.status == .completed)
        let record = Reminder.Record(
            id: reminder.id,
            listID: reminder.list,
            title: reminder.title,
            notes: reminder.notes,
            dueDate: now,
            hasTime: true,
            flagged: true,
            priority: .high,
            status: .completed,
            position: 4,
            location: .gettingInCar,
            repeats: .weekly,
            created: reminder.created
        )
        #expect(Reminder.Record.Draft(record) == draft)
        #expect(Reminder(Reminder.Record.Row(reminder: record, tags: ["car", "kids"])) == reminder)
        var pending = record
        pending.status = .pending
        #expect(pending.completed && Reminder(Reminder.Record.Row(reminder: pending, tags: [])).completion == .completed)
        #expect(Reminder.Record.Counts(all: 3, flagged: 1)[.all] == 3 && Reminder.Record.Counts()[.completed] == nil)
    }

    @Test func `filters default to hiding completed reminders except Completed`() {
        #expect(Reminders.Filter.Preference.default(for: .completed).showCompleted)
        #expect(Reminders.Filter.Preference.default(for: .all) == Reminders.Filter.Preference(key: Reminders.Filter.Key(.all), ordering: .dueDate, showCompleted: false))
        #expect(Reminders.Filter.Preference.default(for: .list(list)).id == Reminders.Filter.Key(.list(list)))
    }

    @Test func `an overview finds its lists and ranks its tags, and a detail knows its ids`() {
        let personal = List<Reminder>.Record(List(id: list, title: "Personal"))
        let overview = Reminders.Overview.Contents(
            lists: [List<Reminder>.Record.Entry(list: personal, count: 2)],
            counts: Reminder.Record.Counts(all: 2),
            tags: [
                Tag<Reminder>.Record.Entry(tag: Tag<Reminder>.Record(Tag(title: "social")), count: 3),
                Tag<Reminder>.Record.Entry(tag: Tag<Reminder>.Record(Tag(title: "Adulting")), count: 1),
                Tag<Reminder>.Record.Entry(tag: Tag<Reminder>.Record(Tag(title: "car")), count: 0),
            ]
        )
        #expect(overview.list(list) == personal && overview.list(List<Reminder>.ID(UUID())) == nil)
        #expect(overview.rankedTags.map(\.title) == ["social", "Adulting", "car"])
        #expect(overview.usedTags.map(\.title) == ["Adulting", "social"])
        let record = Reminder.Record(id: Reminder.ID(UUID()), listID: list, title: "Call", created: now)
        let detail = Reminders.Filter.Detail.Contents(filter: .list(list), preference: .default(for: .list(list)), rows: [Reminder.Record.Row(reminder: record, tags: [])])
        #expect(detail.ids == [record.id] && detail.total == 0)
        let results = Reminders.Search.Contents(sections: [Reminders.Search.Contents.Section(list: personal, rows: [Reminder.Record.Row(reminder: record, tags: ["a"])])])
        #expect(results.shown == 1 && results.sections.first?.id == list)
        #expect(Reminders.Restoration().filter == nil && Reminders.Restoration(filter: Reminders.Filter.Key(.today), editing: record.id).editing == record.id)
    }
}
