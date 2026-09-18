import Foundation
import List
import Reminder
import Reminders
import Reminders_SQL
import Tagged
import Testing

@Suite struct `Reminders SQL` {
    @Test func `a record carries the reminder and its place in the table`() {
        let list = List<Reminder>.ID(UUID())
        let reminder = Reminder(id: Reminder.ID(UUID()), list: list, title: "Milk", completed: true, created: Date(timeIntervalSince1970: 0))
        let draft = Reminder.Record.Draft(reminder, position: 3)
        #expect(draft.position == 3)
        let record = Reminder.Record(id: reminder.id, listID: list, title: "Milk", completed: true, position: 3, created: reminder.created)
        #expect(Reminder(record) == reminder)
    }
}
