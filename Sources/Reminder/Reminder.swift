public import Foundation
public import Interface_Macro
public import List
public import Tagged

@Memberwise
@Draft(excluding: "id", "created")
public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: Tagged<Reminder, UUID>
    public var list: List<Reminder>.ID
    public var title: String = ""
    public var completed: Bool = false
    public var created: Date
}

extension Reminder.Draft {
    public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
}
