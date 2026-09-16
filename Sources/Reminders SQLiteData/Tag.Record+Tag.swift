public import Organizing
public import Reminders

extension Tag<Reminder> {
    public init(_ record: Tag<Reminder>.Record) {
        self.init(title: record.title)
    }
}
