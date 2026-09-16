public import Foundation
import FoundationEssentials_Extensions
import Organizing
public import Reminders
import Tagged

extension Reminder.Sample {
    public struct Scale: Hashable, Sendable {
        public var lists: Int
        public var remindersPerList: Int
        public var tags: Int

        public init(lists: Int, remindersPerList: Int, tags: Int) {
            self.lists = lists
            self.remindersPerList = remindersPerList
            self.tags = tags
        }

        public static let medium = Scale(lists: 10, remindersPerList: 100, tags: 30)
        public static let large = Scale(lists: 30, remindersPerList: 500, tags: 100)
        public static let extreme = Scale(lists: 100, remindersPerList: 1_000, tags: 200)

        public var reminders: Int { lists * remindersPerList }
    }

    public struct Seed: Hashable, Sendable {
        public var scale: Scale
        public var value: UInt64

        public init(scale: Scale, value: UInt64) {
            self.scale = scale
            self.value = value
        }

        public var description: String { "0x" + String(value, radix: 16, uppercase: true) }
    }

    public static func generated(_ scale: Scale, seed: UInt64, at now: Date, calendar: Calendar) -> Reminder.Sample {
        var random = Random(seed: seed)
        func uuid() -> UUID {
            UUID(uuid: (
                random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(),
                random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte(), random.byte()
            ))
        }
        let tagTitles = (0..<scale.tags).map { Words.tag($0) }
        let lists = (0..<scale.lists).map { index in
            List<Reminder>(id: List<Reminder>.ID(uuid()), title: Words.list(index), color: Words.colors[index % Words.colors.count], position: index)
        }
        var reminders: [Reminder] = []
        reminders.reserveCapacity(scale.reminders)
        var position = 0
        for list in lists {
            for _ in 0..<scale.remindersPerList {
                let created = now.addingTimeInterval(-Double(random.next(in: 0..<365 * 24 * 60 * 60)))
                var due: Reminder.Due?
                if random.chance(1, in: 3) {
                    let day = calendar.startOfDay(for: now).addingTimeInterval(Double(random.next(in: 0..<120) - 30) * 86_400)
                    due = random.chance(1, in: 2) ? .day(day) : .moment(day.addingTimeInterval(Double(random.next(in: 6..<22)) * 3_600))
                }
                var tags: Set<Tag<Reminder>.ID> = []
                if !tagTitles.isEmpty, random.chance(2, in: 5) {
                    for _ in 0..<random.next(in: 1..<4) { tags.insert(Tag<Reminder>.ID(rawValue: tagTitles[random.next(in: 0..<tagTitles.count)])) }
                }
                reminders.append(
                    Reminder(
                        id: Reminder.ID(uuid()),
                        list: list.id,
                        title: Words.title(&random),
                        notes: random.chance(1, in: 6) ? Words.note(&random) : "",
                        due: due,
                        flagged: random.chance(1, in: 10),
                        priority: random.chance(1, in: 4) ? Reminder.Priority.allCases[random.next(in: 0..<3)] : nil,
                        completion: random.chance(1, in: 5) ? .completed : .incomplete,
                        tags: tags,
                        position: position,
                        created: created
                    )
                )
                position += 1
            }
        }
        return Reminder.Sample(lists: lists, reminders: reminders, tags: Set(tagTitles.map(Tag<Reminder>.init(title:))))
    }
}

extension Reminder.Sample {
    enum Words {
        static let verbs = ["Buy", "Call", "Email", "Fix", "Plan", "Book", "Review", "Renew", "Pay", "Return", "Clean", "Read", "Schedule", "Cancel", "Pick up", "Send", "Write", "Print", "Order", "Check"]
        static let objects = ["groceries", "the dentist", "the plumber", "flights", "the report", "insurance", "rent", "the library books", "the garage", "chapter four", "the invoice", "the subscription", "the kids", "the parcel", "the essay", "the photos", "new tyres", "the smoke alarm", "the passport", "the budget"]
        static let notes = ["Ask about the weekend plans", "Before Friday", "Compare two quotes first", "Milk\nEggs\nApples", "Needs the account number", "Second reminder", "Check the warranty"]
        static let listNames = ["Personal", "Family", "Business", "Errands", "Home", "Travel", "Health", "Finance", "Garden", "Reading", "Projects", "Gifts", "Car", "School", "Music"]
        static let tagNames = ["adulting", "car", "kids", "night", "optional", "social", "someday", "urgent", "weekend", "work", "home", "health", "money", "travel", "gift", "fun", "chores", "calls", "reading", "fitness"]
        static let colors: [Organizing.Color] = [
            .default,
            Organizing.Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255),
            Organizing.Color(red: 255 / 255, green: 149 / 255, blue: 0),
            Organizing.Color(red: 255 / 255, green: 204 / 255, blue: 0),
            Organizing.Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255),
            Organizing.Color(red: 175 / 255, green: 82 / 255, blue: 222 / 255),
            Organizing.Color(red: 162 / 255, green: 132 / 255, blue: 94 / 255),
        ]

        static func list(_ index: Int) -> String {
            let name = listNames[index % listNames.count]
            return index < listNames.count ? name : "\(name) \(index / listNames.count + 1)"
        }

        static func tag(_ index: Int) -> String {
            let name = tagNames[index % tagNames.count]
            return index < tagNames.count ? name : "\(name)\(index / tagNames.count + 1)"
        }

        static func title(_ random: inout Random) -> String {
            "\(verbs[random.next(in: 0..<verbs.count)]) \(objects[random.next(in: 0..<objects.count)])"
        }

        static func note(_ random: inout Random) -> String { notes[random.next(in: 0..<notes.count)] }
    }
}

extension Reminder.Sample {
    public struct Random: RandomNumberGenerator, Hashable, Sendable {
        private var state: UInt64

        public init(seed: UInt64) { state = seed }

        public mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }

        mutating func byte() -> UInt8 { UInt8(truncatingIfNeeded: next()) }

        mutating func next(in range: Range<Int>) -> Int { Int.random(in: range, using: &self) }

        mutating func chance(_ numerator: Int, in denominator: Int) -> Bool { next(in: 0..<denominator) < numerator }
    }
}
