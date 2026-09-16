import Foundation
import Organizing
import Standard_Library_Extensions
import Tagged

extension Reminders.Filter {
    public init?(key: Reminders.Filter.Key) {
        switch key.rawValue {
        case "all": self = .all
        case "completed": self = .completed
        case "flagged": self = .flagged
        case "scheduled": self = .scheduled
        case "today": self = .today
        case let raw:
            if let uuid = raw.removing(prefix: "list_").flatMap({ UUID(uuidString: String($0)) }) {
                self = .list(List<Reminder>.ID(uuid))
            } else if let tags = raw.removing(prefix: "tags_") {
                self = .tags(Set(tags.split(separator: Character.unitSeparator).map { Tag<Reminder>.ID(String($0)) }))
            } else {
                return nil
            }
        }
    }
}
