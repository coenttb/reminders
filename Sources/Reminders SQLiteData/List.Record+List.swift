public import Organizing
public import Reminders

extension List<Reminder> {
    public init(_ record: List<Reminder>.Record) {
        self.init(id: record.id, title: record.title, color: Color(record.color), position: record.position)
    }
}
