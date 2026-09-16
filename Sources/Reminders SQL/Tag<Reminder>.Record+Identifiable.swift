public import Organizing
public import Reminders
public import Tagged

extension Tag<Reminder>.Record: Identifiable {
    public var id: Tag<Reminder>.ID { Tag<Reminder>.ID(title) }
}
