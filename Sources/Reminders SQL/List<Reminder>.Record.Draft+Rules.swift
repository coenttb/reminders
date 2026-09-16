public import Organizing
public import Reminders

extension List<Reminder>.Record.Draft {
    /// A name of only whitespace is no list.
    public static func isBlank(_ draft: Self) -> Bool { draft.title.allSatisfy(\.isWhitespace) }

    public var isBlank: Bool { Self.isBlank(self) }
}
