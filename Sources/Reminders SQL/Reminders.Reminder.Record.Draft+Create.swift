public import Foundation
public import Organizing
public import Reminders
public import Tagged

extension Reminders.Reminder.Record.Draft {
    /// A draft from its fields. The compiler's memberwise initialiser for the generated draft is
    /// internal and cannot be redeclared as public, so other modules build drafts here.
    public static func create(
        id: Reminder.ID? = nil,
        listID: List<Reminder>.ID,
        title: String = "",
        notes: String = "",
        dueDate: Date? = nil,
        hasTime: Bool = false,
        flagged: Bool = false,
        priority: Reminder.Priority? = nil,
        status: Reminder.Record.Status = .incomplete,
        position: Int = 0,
        location: Reminder.Location? = nil,
        repeats: Reminder.Repeat = .never,
        created: Date
    ) -> Self {
        Self(
            id: id,
            listID: listID,
            title: title,
            notes: notes,
            dueDate: dueDate,
            hasTime: hasTime,
            flagged: flagged,
            priority: priority,
            status: status,
            position: position,
            location: location,
            repeats: repeats,
            created: created
        )
    }
}
