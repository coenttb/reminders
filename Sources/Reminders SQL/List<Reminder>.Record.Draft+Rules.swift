public import Organizing
public import Reminders

extension List<Reminder>.Record.Draft {
    public static func isBlank(_ draft: Self) -> Bool { draft.title.allSatisfy(\.isWhitespace) }

    public var isBlank: Bool { Self.isBlank(self) }
}
