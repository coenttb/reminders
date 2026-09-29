public import Interface_Macro
public import List
public import RFC_4122
public import Tagged
public import Time

@Memberwise
@Draft(excluding: "id", "created")
public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: Tagged<Reminder, RFC_4122.UUID>
    public var list: List<Reminder>.ID
    public var title: String = ""
    public var completed: Bool = false
    public var created: Time.Instant
}

extension Reminder.Draft {
    public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
}

extension Reminder.Draft: Hashable, Sendable {}
