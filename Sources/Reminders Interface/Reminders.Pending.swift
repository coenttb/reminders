public import Reminders
public import Tagged

extension Reminders {
    public struct Pending: Hashable, Sendable {
        public var ids: Set<Reminder.ID>

        public init(_ ids: Set<Reminder.ID> = []) {
            self.ids = ids
        }
    }
}

extension Reminders.Pending {
    public static let grace: Duration = .seconds(5)

    public var isEmpty: Bool { ids.isEmpty }

    public func contains(_ id: Reminder.ID) -> Bool { ids.contains(id) }

    public static func toggling(_ pending: Self, _ id: Reminder.ID) -> Self {
        var toggled = pending
        if toggled.ids.remove(id) == nil { toggled.ids.insert(id) }
        return toggled
    }

    public mutating func toggle(_ id: Reminder.ID) { self = Self.toggling(self, id) }

    public static func elapsing(_ pending: Self) -> Self { Self() }

    public mutating func elapse() { self = Self.elapsing(self) }
}

extension Reminders.Pending: ExpressibleByArrayLiteral {
    public init(arrayLiteral ids: Reminder.ID...) {
        self.init(Set(ids))
    }
}
