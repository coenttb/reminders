import Foundation
import List
import Reminder
import Reminders
import Reminders_Sample
import Testing

@Suite struct `Reminders sample` {
    @Test func `every sample reminder belongs to a sample list`() {
        let sample = Reminders.sample(at: Date(timeIntervalSince1970: 0))
        let lists = Set(sample.lists.map(\.id))
        #expect(sample.reminders.allSatisfy { lists.contains($0.list) })
    }
}
