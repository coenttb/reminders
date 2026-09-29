import List
import Reminder
import Reminders
import Reminders_Sample
import Testing
import Time

@Suite struct `Reminders sample` {
    @Test func `every sample reminder belongs to a sample list`() {
        let sample = Reminders.sample(at: Time.Instant(secondsSinceUnixEpoch: 0))
        let lists = Set(sample.lists.map(\.id))
        #expect(sample.reminders.allSatisfy { lists.contains($0.list) })
    }
}
