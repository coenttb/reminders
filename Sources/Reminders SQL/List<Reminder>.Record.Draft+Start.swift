public import Models
public import Reminder

extension List<Reminder>.Record.Draft {
    public static func start() -> Self {
        Self()
    }
}
