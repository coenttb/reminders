public import Interface_Macro
public import Foundation
public import List
public import Reminder
public import Reminders
import Tagged

extension Reminders {
    @Memberwise
    public struct Sample: Hashable, Sendable {
        public var lists: [List<Reminder>]
        public var reminders: [Reminder] = []
    }

    public static func sample(at now: Date) -> Sample {
        func id(_ n: Int) -> UUID {
            let hex = String(n, radix: 16, uppercase: true)
            precondition(n >= 0 && hex.count <= 12)
            return UUID(uuidString: "00000000-0000-0000-000A-" + String(repeating: "0", count: 12 - hex.count) + hex)!
        }
        let personal = List<Reminder>.ID(id(0)), family = List<Reminder>.ID(id(1))
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
