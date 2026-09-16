public import Organizing
public import Reminders

extension List<Reminder>.Record.Draft {
    public static func start() -> Self {
        Self()
    }
}
