import Foundation
import Models
import Reminder
import Tagged
import Testing

@Suite struct `Reminder values` {
    @Test func `a new reminder is blank and open`() {
        let reminder = Reminder(id: Reminder.ID(UUID()), list: Models.List<Reminder>.ID(UUID()), created: Date())
        #expect(reminder.isBlank)
        #expect(!reminder.completed)
    }
}
