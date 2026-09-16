import Foundation
import Organizing
public import Reminders
public import SQLiteData
import Standard_Library_Extensions
import Tagged

extension Reminder.Filter {
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
}
