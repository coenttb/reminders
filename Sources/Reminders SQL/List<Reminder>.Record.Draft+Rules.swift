public import Models
public import Reminder

extension List<Reminder>.Record.Draft {
    public var isBlank: Bool { List<Reminder>.isBlank(title: title) }
}
