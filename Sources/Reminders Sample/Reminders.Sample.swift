public import Interface_Macro
public import List
public import Reminder
public import Reminders
import RFC_4122
import Tagged
public import Time

extension Reminders {
    @Memberwise
    public struct Sample: Hashable, Sendable {
        public var lists: [List<Reminder>]
        public var reminders: [Reminder] = []
    }

    public static func sample(at now: Time.Instant) -> Sample {
        func id(_ n: UInt8) -> RFC_4122.UUID {
            RFC_4122.UUID(bytes: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0x0A, 0, 0, 0, 0, 0, n))
        }
        let personal = List<Reminder>.ID(id(0)), family = List<Reminder>.ID(id(1))
        return Sample(
            lists: [
                .init(id: personal, title: "Personal"),
                .init(id: family, title: "Family"),
            ],
            reminders: [
                .init(id: Reminder.ID(id(10)), list: personal, title: "Groceries", created: now - .seconds(3 * 86_400)),
                .init(id: Reminder.ID(id(11)), list: personal, title: "Haircut", completed: true, created: now - .seconds(2 * 86_400)),
                .init(id: Reminder.ID(id(12)), list: family, title: "Call Mom", created: now - .seconds(86_400)),
            ]
        )
    }
}
