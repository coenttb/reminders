public import Foundation
public import Models
public import Tagged

public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: Tagged<Reminder, UUID>
    public var list: Models.List<Reminder>.ID
    public var title: String
    public var completed: Bool
    public var created: Date

    public init(id: ID, list: Models.List<Reminder>.ID, title: String = "", completed: Bool = false, created: Date) {
        self.id = id
        self.list = list
        self.title = title
        self.completed = completed
        self.created = created
    }
}

extension Reminder {
    public var isBlank: Bool { title.allSatisfy(\.isWhitespace) }
}
