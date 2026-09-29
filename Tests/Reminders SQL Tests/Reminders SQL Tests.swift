import List
import Reminder
import Reminders
import Reminders_SQL
import RFC_4122
import Tagged
import Testing
import Time

@Suite struct `Reminders SQL` {
    @Test func `a record carries the reminder and its place in the table`() throws {
        let list = List<Reminder>.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000001"))
        let reminder = Reminder(
            id: Reminder.ID(try RFC_4122.UUID("00000000-0000-0000-0000-000000000002")),
            list: list, title: "Milk", completed: true, created: Time.Instant(secondsSinceUnixEpoch: 0)
        )
        let draft = Reminder.Record.Draft(reminder, position: 3)
        #expect(draft.position == 3)
        let record = Reminder.Record(id: reminder.id, listID: list, title: "Milk", completed: true, position: 3, created: reminder.created)
        #expect(Reminder(record) == reminder)
    }
}
