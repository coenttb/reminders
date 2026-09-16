import Foundation
import Organizing
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
}
