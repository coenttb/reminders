public import Foundation
import FoundationEssentials_Extensions
public import Models
public import Reminder
public import Reminders
import Standard_Library_Extensions
public import Tagged

extension Reminders {
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

    public static func sample(at now: Date) -> Sample {
        func id(_ n: Int) -> UUID {
            let hex = String(n, radix: 16, uppercase: true)
            return UUID(uuidString: "00000000-0000-0000-000A-" + String(repeating: "0", count: 12 - hex.count) + hex)!
        }
        func day(_ offset: Double) -> Date { now.addingTimeInterval(offset.days) }
        let personal = List<Reminder>.ID(id(0)), family = List<Reminder>.ID(id(1)), business = List<Reminder>.ID(id(2))
        return Sample(
            lists: [
                List(id: personal, title: "Personal", color: .default),
                List(id: family, title: "Family", color: Color(red: 237 / 255, green: 137 / 255, blue: 53 / 255)),
                List(id: business, title: "Business", color: Color(red: 178 / 255, green: 93 / 255, blue: 211 / 255)),
            ],
            reminders: [
                Reminder(id: Reminder.ID(id(10)), list: personal, title: "Groceries", notes: "Milk\nEggs\nApples\nOatmeal\nSpinach", tags: ["someday", "optional", "adulting"], created: day(-30)),
                Reminder(id: Reminder.ID(id(11)), list: personal, title: "Haircut", due: .day(day(-2)), flagged: true, tags: ["someday", "optional"], created: day(-9)),
                Reminder(id: Reminder.ID(id(12)), list: personal, title: "Doctor appointment", notes: "Ask about diet", due: .moment(now), priority: .high, tags: ["adulting"], created: day(-3)),
                Reminder(id: Reminder.ID(id(13)), list: personal, title: "Take a walk", due: .day(day(-190)), completed: true, tags: ["car", "kids", "social"], created: day(-200)),
                Reminder(id: Reminder.ID(id(14)), list: personal, title: "Buy concert tickets", due: .day(now), tags: ["social", "night"], created: day(-1)),
                Reminder(id: Reminder.ID(id(15)), list: family, title: "Pick up kids from school", due: .moment(day(2)), priority: .high, flagged: true, created: day(-5)),
                Reminder(id: Reminder.ID(id(16)), list: family, title: "Get laundry", due: .day(day(-2)), priority: .low, completed: true, created: day(-12)),
                Reminder(id: Reminder.ID(id(17)), list: family, title: "Take out trash", due: .day(day(4)), priority: .high, created: day(-2)),
                Reminder(id: Reminder.ID(id(18)), list: business, title: "Call accountant", notes: "Status of tax return\nExpenses for next year\nChanging payroll company", due: .day(day(2)), created: day(-7)),
                Reminder(id: Reminder.ID(id(19)), list: business, title: "Send weekly emails", due: .day(day(-2)), priority: .medium, completed: true, created: day(-14)),
                Reminder(id: Reminder.ID(id(20)), list: business, title: "Prepare for WWDC", due: .day(day(2)), tags: ["social"], created: day(-4)),
            ],
            tags: Set(["car", "kids", "someday", "optional", "social", "night", "adulting"].map(Tag<Reminder>.init(_:)))
        )
    }
}

extension Reminders.Sample {
    public static func generated(_ scale: Scale, seed: UInt64, at now: Date, calendar: Calendar) -> Reminders.Sample {
        var random = Random(seed: seed)
        func uuid() -> UUID {
            UUID(uuid: (
                random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(),
                random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte()
            ))
        }
        let tagTitles = (0..<scale.tags).map { Words.tag($0) }
        let lists = (0..<scale.lists).map { index in
            List<Reminder>(id: List<Reminder>.ID(uuid()), title: Words.list(index), color: Words.colors[index % Words.colors.count])
        }
        var reminders: [Reminder] = []
        reminders.reserveCapacity(scale.reminders)
        for list in lists {
            for _ in 0..<scale.remindersPerList {
                let created = now.addingTimeInterval(-Double(random.next(in: 0..<365 * 24 * 60 * 60)))
                var due: Reminder.Due?
                if random.chance(1, in: 3) {
                    let day = calendar.startOfDay(for: now).addingTimeInterval(Double(random.next(in: 0..<120) - 30) * 86_400)
                    due = random.chance(1, in: 2) ? .day(day) : .moment(day.addingTimeInterval(Double(random.next(in: 6..<22)) * 3_600))
                }
                var tags: Set<Tag<Reminder>> = []
                if !tagTitles.isEmpty, random.chance(2, in: 5) {
                    for _ in 0..<random.next(in: 1..<4) { tags.insert(Tag<Reminder>(tagTitles[random.next(in: 0..<tagTitles.count)])) }
                }
                reminders.append(
                    Reminder(
                        id: Reminder.ID(uuid()),
                        list: list.id,
                        title: Words.title(&random),
                        notes: random.chance(1, in: 6) ? Words.note(&random) : "",
                        due: due,
                        priority: random.chance(1, in: 4) ? Reminder.Priority.allCases[random.next(in: 0..<3)] : nil,
                        flagged: random.chance(1, in: 10),
                        completed: random.chance(1, in: 5),
                        tags: tags,
                        created: created
                    )
                )
            }
        }
        return Reminders.Sample(lists: lists, reminders: reminders, tags: Set(tagTitles.map(Tag<Reminder>.init(_:))))
    }
}
