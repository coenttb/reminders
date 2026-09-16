import Foundation
import Organizing
public import Reminders
public import StructuredQueries
import Standard_Library_Extensions
import Tagged

extension Reminders.Filter {
    public struct Key: RawRepresentable, Hashable, Sendable, QueryBindable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension Reminders.Filter.Key {
    private static let separator = String(Character.unitSeparator)

    public init(_ filter: Reminders.Filter) {
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
