public import Reminders
public import Tagged

extension Reminder.Completion {
    /// The grace period: the reminders whose completion was tapped and can still be undone.
    /// The period is counted from the set's last change, so the latest tap or reversal gets
    /// the whole of it; when it elapses every member is completed.
    public struct Pending: Hashable, Sendable {
        public var ids: Set<Reminder.ID>

        public init(_ ids: Set<Reminder.ID> = []) {
            self.ids = ids
        }
    }
}

extension Reminder.Completion.Pending {
    /// How long a tap can be undone.
    public static let grace: Duration = .seconds(5)

    public var isEmpty: Bool { ids.isEmpty }

    public func contains(_ id: Reminder.ID) -> Bool { ids.contains(id) }

    /// The tap: an incomplete reminder starts its period; one in its period is reverted.
    public static func toggling(_ pending: Self, _ id: Reminder.ID) -> Self {
        var toggled = pending
        if toggled.ids.remove(id) == nil { toggled.ids.insert(id) }
        return toggled
    }

    public mutating func toggle(_ id: Reminder.ID) { self = Self.toggling(self, id) }

    /// The period elapsed: nothing is pending any more.
    public static func elapsing(_ pending: Self) -> Self { Self() }

    public mutating func elapse() { self = Self.elapsing(self) }
}

extension Reminder.Completion.Pending: ExpressibleByArrayLiteral {
    public init(arrayLiteral ids: Reminder.ID...) {
        self.init(Set(ids))
    }
}
