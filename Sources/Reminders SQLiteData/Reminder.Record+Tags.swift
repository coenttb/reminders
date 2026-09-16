public import Organizing
public import Reminders
import Standard_Library_Extensions
public import Tagged

extension Reminder.Record {
    static let tagSeparator = String(Character.unitSeparator)

    static func tags(from list: String?) -> Set<Tag<Reminder>.ID> {
        Set((list ?? "").split(separator: tagSeparator).map { Tag<Reminder>.ID(String($0)) })
    }
}
