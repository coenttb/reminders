import Foundation
import FoundationEssentials_Extensions
import Models
import Reminder
import Reminders
import Reminders_Sample
import Testing
import Tagged

@Suite struct `Reminder sample` {
    let now = Date(timeIntervalSince1970: 1_234_567_890)
    let calendar = Calendar(identifier: .gregorian)

    @Test func `the sample is three lists, eleven reminders, and seven tags around now`() throws {
        let sample = Reminders.sample(at: now)
        #expect(sample.lists.map(\.title) == ["Personal", "Family", "Business"])
        #expect(sample.reminders.count == 11 && sample.tags.count == 7)
        #expect(sample.reminders.filter(\.completed).count == 3)
        #expect(sample.reminders.compactMap(\.due).filter(\.hasTime).count == 2)
        let doctor = try #require(sample.reminder(Reminder.ID(UUID(uuidString: "00000000-0000-0000-000A-00000000000C")!)))
        #expect(doctor.title == "Doctor appointment" && doctor.due == .moment(now))
        #expect(Set(sample.reminders.map(\.list)) == Set(sample.lists.map(\.id)))
        #expect(sample.reminders.map(\.position) == Array(0..<11))
    }

    @Test func `a generated sample is a function of its seed and fills its scale`() {
        let scale = Reminders.Sample.Scale(lists: 4, remindersPerList: 50, tags: 25)
        let a = Reminders.Sample.generated(scale, seed: 7, at: now, calendar: calendar)
        let b = Reminders.Sample.generated(scale, seed: 7, at: now, calendar: calendar)
        let c = Reminders.Sample.generated(scale, seed: 8, at: now, calendar: calendar)
        #expect(a == b)
        #expect(a != c)
        #expect(a.lists.count == 4 && a.reminders.count == 200 && a.tags.count == 25)
        #expect(a.lists.map(\.title) == ["Personal", "Family", "Business", "Errands"])
        #expect(a.tags.contains(Tag(title: "adulting")) && a.tags.contains(Tag(title: "adulting2")))
        let listIDs = Set(a.lists.map(\.id)), tagIDs = Set(a.tags.map(\.id))
        #expect(a.reminders.allSatisfy { listIDs.contains($0.list) && $0.tags.isSubset(of: tagIDs) })
        #expect(Set(a.reminders.map(\.id)).count == 200)
        #expect(a.reminders.map(\.position) == Array(0..<200))
        #expect(a.reminders.allSatisfy { $0.created <= now && $0.created > now.addingTimeInterval(-366 * 86_400) })
        #expect(!a.reminders.filter(\.completed).isEmpty && !a.reminders.filter { $0.due != nil }.isEmpty)
        #expect(Reminders.Sample.Scale.extreme.reminders == 100_000)
        #expect(Reminders.Sample.Seed(scale: scale, value: 255).description == "0xFF")
    }
}
