public import Foundation
import FoundationEssentials_Extensions
public import Organizing
public import Reminders
import Standard_Library_Extensions
public import Tagged

extension Reminder {
    /// A set of records to fill the database with: what the first run starts from, and what
    /// the seed button resets to.
    public struct Sample: Hashable, Sendable {
        public var lists: [List<Reminder>]
        public var reminders: [Reminder]
        public var tags: Set<Tag<Reminder>>

        public init(lists: [List<Reminder>], reminders: [Reminder] = [], tags: Set<Tag<Reminder>> = []) {
            self.lists = lists
            self.reminders = reminders
            self.tags = tags
        }

        public func reminder(_ id: Reminder.ID) -> Reminder? { reminders.first(id: id) }
    }

    /// The reference fixture relative to a given now, so tests can fix the calendar: three
    /// lists, eleven reminders around today, seven tags.
    public static func sample(at now: Date) -> Sample {
        func id(_ n: Int) -> UUID {
            let hex = String(n, radix: 16, uppercase: true)
            // A fixture identifier sits in a segment the incrementing test generator never fills.
            return UUID(uuidString: "00000000-0000-0000-000A-" + String(repeating: "0", count: 12 - hex.count) + hex)!
        }
        func day(_ offset: Double) -> Date { now.addingTimeInterval(offset.days) }
        let personal = List<Reminder>.ID(id(0)), family = List<Reminder>.ID(id(1)), business = List<Reminder>.ID(id(2))
        return Sample(
            lists: [
                List(id: personal, title: "Personal", color: .default, position: 0),
                List(id: family, title: "Family", color: Color(red: 237 / 255, green: 137 / 255, blue: 53 / 255), position: 1),
                List(id: business, title: "Business", color: Color(red: 178 / 255, green: 93 / 255, blue: 211 / 255), position: 2),
            ],
            reminders: [
                Reminder(id: Reminder.ID(id(10)), list: personal, title: "Groceries", notes: "Milk\nEggs\nApples\nOatmeal\nSpinach", tags: ["someday", "optional", "adulting"], position: 0),
                Reminder(id: Reminder.ID(id(11)), list: personal, title: "Haircut", due: .day(day(-2)), flagged: true, tags: ["someday", "optional"], position: 1),
                Reminder(id: Reminder.ID(id(12)), list: personal, title: "Doctor appointment", notes: "Ask about diet", due: .moment(now), priority: .high, tags: ["adulting"], position: 2),
                Reminder(id: Reminder.ID(id(13)), list: personal, title: "Take a walk", due: .day(day(-190)), completion: .completed, tags: ["car", "kids", "social"], position: 3),
                Reminder(id: Reminder.ID(id(14)), list: personal, title: "Buy concert tickets", due: .day(now), tags: ["social", "night"], position: 4),
                Reminder(id: Reminder.ID(id(15)), list: family, title: "Pick up kids from school", due: .moment(day(2)), flagged: true, priority: .high, position: 5),
                Reminder(id: Reminder.ID(id(16)), list: family, title: "Get laundry", due: .day(day(-2)), priority: .low, completion: .completed, position: 6),
                Reminder(id: Reminder.ID(id(17)), list: family, title: "Take out trash", due: .day(day(4)), priority: .high, position: 7),
                Reminder(id: Reminder.ID(id(18)), list: business, title: "Call accountant", notes: "Status of tax return\nExpenses for next year\nChanging payroll company", due: .day(day(2)), position: 8),
                Reminder(id: Reminder.ID(id(19)), list: business, title: "Send weekly emails", due: .day(day(-2)), priority: .medium, completion: .completed, position: 9),
                Reminder(id: Reminder.ID(id(20)), list: business, title: "Prepare for WWDC", due: .day(day(2)), tags: ["social"], position: 10),
            ],
            tags: Set(["car", "kids", "someday", "optional", "social", "night", "adulting"].map(Tag<Reminder>.init(title:)))
        )
    }
}
