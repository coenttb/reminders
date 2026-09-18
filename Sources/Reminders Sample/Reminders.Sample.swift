public import Foundation
public import Models
public import Reminder
public import Reminders
public import Tagged

extension Reminders {
    public struct Sample: Hashable, Sendable {
        public var lists: [Models.List<Reminder>]
        public var reminders: [Reminder]

        public init(lists: [Models.List<Reminder>], reminders: [Reminder] = []) {
            self.lists = lists
            self.reminders = reminders
        }
    }

    public static func sample(at now: Date) -> Sample {
        func id(_ n: Int) -> UUID {
            UUID(uuidString: "00000000-0000-0000-000A-" + String(format: "%012X", n))!
        }
        let personal = Models.List<Reminder>.ID(id(0)), family = Models.List<Reminder>.ID(id(1))
        return Sample(
            lists: [
                .init(id: personal, title: "Personal"),
                .init(id: family, title: "Family"),
            ],
            reminders: [
                .init(id: Reminder.ID(id(10)), list: personal, title: "Groceries", created: now.addingTimeInterval(-3 * 86_400)),
                .init(id: Reminder.ID(id(11)), list: personal, title: "Haircut", completed: true, created: now.addingTimeInterval(-2 * 86_400)),
                .init(id: Reminder.ID(id(12)), list: family, title: "Call Mom", created: now.addingTimeInterval(-86_400)),
            ]
        )
    }
}
