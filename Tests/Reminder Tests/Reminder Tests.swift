import Foundation
import List
import Reminder
import Tagged
import Testing

@Suite struct `Reminder values` {
    @Test func `a new reminder is blank and open`() {
        let reminder = Reminder(id: Reminder.ID(UUID()), list: List<Reminder>.ID(UUID()), created: Date())
        #expect(reminder.isBlank)
        #expect(!reminder.completed)
    }
}
