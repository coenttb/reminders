import Foundation
import Organizing
public import Reminders
public import SQLiteData
import Standard_Library_Extensions
import Tagged

extension Reminder.Filter {
    /// The stored form of a filter, also the key preferences are stored under: a smart group's
    /// name, `list_` and the list's identifier, or `tags_` and the tag titles. Tag titles are
    /// free text, so they are joined by the unit separator, and sorted so the same set of tags
    /// shares one key whatever order it was opened in.
    public struct Key: RawRepresentable, Hashable, Sendable, QueryBindable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension Reminder.Filter.Key {
    private static let separator = String(Character.unitSeparator)

    public init(_ filter: Reminder.Filter) {
        rawValue = switch filter {
        case .all: "all"
        case .completed: "completed"
        case .flagged: "flagged"
        case .scheduled: "scheduled"
        case .today: "today"
        case let .list(id): "list_\(id.rawValue.uuidString)"
        case let .tags(tags): "tags_" + tags.sorted().map(\.rawValue).joined(separator: Self.separator)
        }
    }

    /// The filter the key names, if it names one.
    public var filter: Reminder.Filter? { Reminder.Filter(key: self) }
}

extension Reminder.Filter {
    public var key: Key { Key(self) }

    public init?(key: Key) {
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
                self = .tags(tags.split(separator: Character.unitSeparator).map { Tag<Reminder>.ID(String($0)) })
            } else {
                return nil
            }
        }
    }
}
