public import Models
public import Reminder

extension Tag<Reminder>.Record: Identifiable {
    public var id: Tag<Reminder> { Tag<Reminder>(title) }
}
